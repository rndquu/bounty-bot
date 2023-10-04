import { BigNumber, ethers } from "ethers";
// import { getLabelChanges, getPenalty, getWalletAddress, getUserMultiplier, removePenalty } from "../../adapters/supabase";
import { getBotConfig, getBotContext, getLogger } from "../../bindings";
import {
  addLabelToIssue,
  checkUserPermissionForRepoAndOrg,
  clearAllPriceLabelsOnIssue,
  deleteLabel,
  generatePermit2Signature,
  getAllIssueComments,
  getTokenSymbol,
  savePermitToDB,
  wasIssueReopened,
  getAllIssueAssignEvents,
  addCommentToIssue,
} from "../../helpers";
import { UserType, Payload, StateReason, Comment, User, Incentives, Issue } from "../../types";
import { shortenEthAddress } from "../../utils";
import { taskInfo } from "../wildcard";
import Decimal from "decimal.js";
import { GLOBAL_STRINGS } from "../../configs";
import { isParentIssue } from "../pricing";
import { getUserMultiplier, getWalletAddress, RewardsResponse } from "../comment";
import { isEmpty } from "lodash";

export interface IncentivesCalculationResult {
  paymentToken: string;
  rpc: string;
  evmNetworkId: number;
  privateKey: string;
  permitMaxPrice: number;
  baseMultiplier: number;
  incentives: Incentives;
  issueCreatorMultiplier: number;
  recipient: string;
  multiplier: number;
  issue: Issue;
  payload: Payload;
  comments: Comment[];
  issueDetailed: {
    isTask: boolean;
    timelabel: string;
    priorityLabel: string;
    priceLabel: string;
  };
  assignee: User;
  tokenSymbol: string;
  claimUrlRegex: RegExp;
}

export interface RewardByUser {
  account: string;
  priceInBigNumber: Decimal;
  userId: string | undefined;
  issueId: string;
  type: string | undefined;
  user: string | undefined;
}

/**
 * Collect the information required for the permit generation and error handling
 */

export const incentivesCalculation = async (): Promise<IncentivesCalculationResult> => {
  const context = getBotContext();
  const {
    payout: { paymentToken, rpc, permitBaseUrl, evmNetworkId, privateKey },
    mode: { incentiveMode, permitMaxPrice },
    price: { incentives, issueCreatorMultiplier, baseMultiplier },
    publicAccessControl: accessControl,
  } = getBotConfig();
  const logger = getLogger();
  const payload = context.payload as Payload;
  const issue = payload.issue;
  const { repository, organization } = payload;

  const id = organization?.id || repository?.id; // repository?.id as fallback

  if (!issue) {
    throw new Error("Permit generation skipped because issue is undefined");
  }

  if (accessControl.fundExternalClosedIssue) {
    const userHasPermission = await checkUserPermissionForRepoAndOrg(payload.sender.login, context);

    if (!userHasPermission) {
      throw new Error("Permit generation disabled because this issue has been closed by an external contributor.");
    }
  }

  const comments = await getAllIssueComments(issue.number);

  const wasReopened = await wasIssueReopened(issue.number);
  const claimUrlRegex = new RegExp(`\\((${permitBaseUrl}\\?claim=\\S+)\\)`);
  const permitCommentIdx = comments.findIndex((e) => e.user.type === UserType.Bot && e.body.match(claimUrlRegex));

  if (wasReopened && permitCommentIdx !== -1) {
    const permitComment = comments[permitCommentIdx];
    const permitUrl = permitComment.body.match(claimUrlRegex);
    if (!permitUrl || permitUrl.length < 2) {
      logger.error(`Permit URL not found`);
      throw new Error("Permit generation skipped because permit URL not found");
    }
    const url = new URL(permitUrl[1]);
    const claimBase64 = url.searchParams.get("claim");
    if (!claimBase64) {
      logger.error(`Permit claim search parameter not found`);
      throw new Error("Permit generation skipped because permit claim search parameter not found");
    }
    let evmNetworkId = url.searchParams.get("network");
    if (!evmNetworkId) {
      evmNetworkId = "1";
    }
    let claim;
    try {
      claim = JSON.parse(Buffer.from(claimBase64, "base64").toString("utf-8"));
    } catch (err: unknown) {
      logger.error(`${err}`);
      throw new Error("Permit generation skipped because permit claim is invalid");
    }
    const amount = BigNumber.from(claim.permit.permitted.amount);
    const tokenAddress = claim.permit.permitted.token;

    // extract assignee
    const events = await getAllIssueAssignEvents(issue.number);
    if (events.length === 0) {
      logger.error(`No assignment found`);
      throw new Error("Permit generation skipped because no assignment found");
    }
    const assignee = events[0].assignee.login;

    try {
      await removePenalty(assignee, payload.repository.full_name, tokenAddress, evmNetworkId, amount);
    } catch (err) {
      logger.error(`Failed to remove penalty: ${err}`);
      throw new Error("Permit generation skipped because failed to remove penalty");
    }

    logger.info(`Penalty removed`);
    throw new Error("Permit generation skipped, penalty removed");
  }

  if (!incentiveMode) {
    logger.info(`No incentive mode. skipping to process`);
    throw new Error("No incentive mode. skipping to process");
  }

  if (privateKey == "") {
    logger.info("Permit generation disabled because wallet private key is not set.");
    throw new Error("Permit generation disabled because wallet private key is not set.");
  }

  if (issue.state_reason !== StateReason.COMPLETED) {
    logger.info("Permit generation disabled because this is marked as unplanned.");
    throw new Error("Permit generation disabled because this is marked as unplanned.");
  }

  logger.info(`Checking if the issue is a parent issue.`);
  if (issue.body && isParentIssue(issue.body)) {
    logger.error("Permit generation disabled because this is a collection of issues.");
    await clearAllPriceLabelsOnIssue();
    throw new Error("Permit generation disabled because this is a collection of issues.");
  }

  logger.info(`Handling issues.closed event, issue: ${issue.number}`);
  for (const botComment of comments.filter((cmt) => cmt.user.type === UserType.Bot).reverse()) {
    const botCommentBody = botComment.body;
    if (botCommentBody.includes(GLOBAL_STRINGS.autopayComment)) {
      const pattern = /\*\*(\w+)\*\*/;
      const res = botCommentBody.match(pattern);
      if (res) {
        if (res[1] === "false") {
          logger.info(`Skipping to generate permit2 url, reason: autoPayMode for this issue: false`);
          throw new Error(`Permit generation disabled because automatic payment for this issue is disabled.`);
        }
        break;
      }
    }
  }

  if (permitMaxPrice == 0 || !permitMaxPrice) {
    logger.info(`Skipping to generate permit2 url, reason: { permitMaxPrice: ${permitMaxPrice}}`);
    throw new Error(`Permit generation disabled because permitMaxPrice is 0.`);
  }

  const issueDetailed = taskInfo(issue);
  if (!issueDetailed.isTask) {
    logger.info(`Skipping... its not a task`);
    throw new Error(`Permit generation disabled because this issue didn't qualify for funding.`);
  }

  if (!issueDetailed.priceLabel || !issueDetailed.priorityLabel || !issueDetailed.timelabel) {
    logger.info(`Skipping... its not a task`);
    throw new Error(`Permit generation disabled because this issue didn't qualify for funding.`);
  }

  // check for label altering here
  const labelChanges = await getLabelChanges(repository.full_name, [issueDetailed.priceLabel, issueDetailed.priorityLabel, issueDetailed.timelabel]);

  if (labelChanges) {
    // if approved is still false, it means user was certainly not authorized for that edit
    if (!labelChanges.approved) {
      logger.info(`Skipping... label was changed by unauthorized user`);
      throw new Error(`Permit generation disabled because label: "${labelChanges.label_to}" was modified by an unauthorized user`);
    }
  }

  const assignees = issue?.assignees ?? [];
  const assignee = assignees.length > 0 ? assignees[0] : undefined;
  if (!assignee) {
    logger.info("Skipping to proceed the payment because `assignee` is undefined");
    throw new Error(`Permit generation disabled because assignee is undefined.`);
  }

  if (!issueDetailed.priceLabel) {
    logger.info("Skipping to proceed the payment because price not set");
    throw new Error(`Permit generation disabled because price label is not set.`);
  }

  const recipient = await getWalletAddress(assignee.login);
  if (!recipient || recipient?.trim() === "") {
    logger.info(`Recipient address is missing`);
    throw new Error(`Permit generation skipped because recipient address is missing`);
  }

  const { value: multiplier } = await getUserMultiplier(assignee.id);

  if (multiplier === 0) {
    const errMsg = "Refusing to generate the payment permit because " + `@${assignee.login}` + "'s payment `multiplier` is `0`";
    logger.info(errMsg);
    throw new Error(errMsg);
  }

  const tokenSymbol = await getTokenSymbol(paymentToken, rpc);

  return {
    paymentToken,
    rpc,
    evmNetworkId,
    privateKey,
    recipient,
    multiplier,
    permitMaxPrice,
    baseMultiplier,
    incentives,
    issueCreatorMultiplier,
    issue,
    payload,
    comments,
    issueDetailed: {
      isTask: issueDetailed.isTask,
      timelabel: issueDetailed.timelabel,
      priorityLabel: issueDetailed.priorityLabel,
      priceLabel: issueDetailed.priceLabel,
    },
    assignee,
    tokenSymbol,
    claimUrlRegex,
  };
};

/**
 * Calculate the reward for the assignee
 */

export const calculateIssueAssigneeReward = async (incentivesCalculation: IncentivesCalculationResult): Promise<RewardsResponse> => {
  const logger = getLogger();
  const assigneeLogin = incentivesCalculation.assignee.login;

  let priceInBigNumber = new Decimal(
    incentivesCalculation.issueDetailed.priceLabel.substring(7, incentivesCalculation.issueDetailed.priceLabel.length - 4)
  ).mul(incentivesCalculation.multiplier);
  if (priceInBigNumber.gt(incentivesCalculation.permitMaxPrice)) {
    logger.info("Skipping to proceed the payment because task payout is higher than permitMaxPrice.");
    return { error: `Permit generation disabled because issue's task is higher than ${incentivesCalculation.permitMaxPrice}` };
  }

  // if contributor has any penalty then deduct it from the task
  const penaltyAmount = await getPenalty(
    assigneeLogin,
    incentivesCalculation.payload.repository.full_name,
    incentivesCalculation.paymentToken,
    incentivesCalculation.evmNetworkId.toString()
  );
  if (penaltyAmount.gt(0)) {
    logger.info(`Deducting penalty from task`);
    const taskAmount = ethers.utils.parseUnits(priceInBigNumber.toString(), 18);
    const taskAmountAfterPenalty = taskAmount.sub(penaltyAmount);
    if (taskAmountAfterPenalty.lte(0)) {
      await removePenalty(
        assigneeLogin,
        incentivesCalculation.payload.repository.full_name,
        incentivesCalculation.paymentToken,
        incentivesCalculation.evmNetworkId.toString(),
        taskAmount
      );
      const msg = `Permit generation disabled because task amount after penalty is 0.`;
      logger.info(msg);
      return { error: msg };
    }
    priceInBigNumber = new Decimal(ethers.utils.formatUnits(taskAmountAfterPenalty, 18));
  }

  const account = await getWalletAddress(incentivesCalculation.assignee.id);

  return {
    error: "",
    userId: incentivesCalculation.assignee.node_id,
    username: assigneeLogin,
    reward: [
      {
        priceInBigNumber,
        penaltyAmount,
        account: account || "0x",
        user: "",
        userId: "",
      },
    ],
  };
};

export const handleIssueClosed = async (
  creatorReward: RewardsResponse,
  assigneeReward: RewardsResponse,
  conversationRewards: RewardsResponse,
  pullRequestReviewersReward: RewardsResponse,
  incentivesCalculation: IncentivesCalculationResult
): Promise<{ error: string }> => {
  const logger = getLogger();
  const { comments } = getBotConfig();
  const issueNumber = incentivesCalculation.issue.number;

  let contributorComment = "",
    title = "Task Assignee",
    assigneeComment = "",
    creatorComment = "",
    mergedComment = "",
    pullRequestReviewerComment = "";
  // The mapping between gh handle and comment with a permit url
  const contributorReward: Record<string, string> = {};
  const collaboratorReward: Record<string, string> = {};

  // Rewards by user
  const rewardByUser: RewardByUser[] = [];

  // ASSIGNEE REWARD PRICE PROCESSOR
  let priceInBigNumber = new Decimal(
    incentivesCalculation.issueDetailed.priceLabel.substring(7, incentivesCalculation.issueDetailed.priceLabel.length - 4)
  ).mul(incentivesCalculation.multiplier);
  if (priceInBigNumber.gt(incentivesCalculation.permitMaxPrice)) {
    logger.info("Skipping to proceed the payment because task payout is higher than permitMaxPrice");
    return { error: `Permit generation skipped since issue's task is higher than ${incentivesCalculation.permitMaxPrice}` };
  }

  // COMMENTER REWARD HANDLER
  if (conversationRewards.reward && conversationRewards.reward.length > 0) {
    contributorComment = `#### ${conversationRewards.title} Rewards \n`;

    conversationRewards.reward.map(async (permit) => {
      // Exclude issue creator from commenter rewards
      if (permit.userId !== creatorReward.userId) {
        rewardByUser.push({
          account: permit.account,
          priceInBigNumber: permit.priceInBigNumber,
          userId: permit.userId,
          issueId: incentivesCalculation.issue.node_id,
          type: conversationRewards.title,
          user: permit.user,
        });
      }
    });
  }

  // PULL REQUEST REVIEWERS REWARD HANDLER
  if (pullRequestReviewersReward.reward && pullRequestReviewersReward.reward.length > 0) {
    pullRequestReviewerComment = `#### ${pullRequestReviewersReward.title} Rewards \n`;

    pullRequestReviewersReward.reward.map(async (permit) => {
      // Exclude issue creator from commenter rewards
      if (permit.userId !== creatorReward.userId) {
        rewardByUser.push({
          account: permit.account,
          priceInBigNumber: permit.priceInBigNumber,
          userId: permit.userId,
          issueId: incentivesCalculation.issue.node_id,
          type: pullRequestReviewersReward.title,
          user: permit.user,
        });
      }
    });
  }

  // CREATOR REWARD HANDLER
  // Generate permit for user if its not the same id as assignee
  if (creatorReward && creatorReward.reward && creatorReward.reward[0].account !== "0x" && creatorReward.userId !== incentivesCalculation.assignee.node_id) {
    const { payoutUrl } = await generatePermit2Signature(
      creatorReward.reward[0].account,
      creatorReward.reward[0].priceInBigNumber,
      incentivesCalculation.issue.node_id,
      creatorReward.userId
    );

    creatorComment = `#### ${creatorReward.title} Reward \n### [ **${creatorReward.username}: [ CLAIM ${
      creatorReward.reward[0].priceInBigNumber
    } ${incentivesCalculation.tokenSymbol.toUpperCase()} ]** ](${payoutUrl})\n`;
    if (payoutUrl) {
      logger.info(`Permit url generated for creator. reward: ${payoutUrl}`);
    }
    // Add amount to assignee if assignee is the creator
  } else if (
    creatorReward &&
    creatorReward.reward &&
    creatorReward.reward[0].account !== "0x" &&
    creatorReward.userId === incentivesCalculation.assignee.node_id
  ) {
    priceInBigNumber = priceInBigNumber.add(creatorReward.reward[0].priceInBigNumber);
    title += " and Creator";
  } else if (creatorReward && creatorReward.reward && creatorReward.reward[0].account === "0x") {
    logger.info(`Skipping to generate a permit url for missing account. fallback: ${creatorReward.fallbackReward}`);
  }

  // ASSIGNEE REWARD HANDLER
  if (assigneeReward && assigneeReward.reward && assigneeReward.reward[0].account !== "0x") {
    const { txData, payoutUrl } = await generatePermit2Signature(
      assigneeReward.reward[0].account,
      assigneeReward.reward[0].priceInBigNumber,
      incentivesCalculation.issue.node_id,
      incentivesCalculation.assignee.node_id
    );
    const tokenSymbol = await getTokenSymbol(incentivesCalculation.paymentToken, incentivesCalculation.rpc);
    const shortenRecipient = shortenEthAddress(assigneeReward.reward[0].account, `[ CLAIM ${priceInBigNumber} ${tokenSymbol.toUpperCase()} ]`.length);
    logger.info(`Posting a payout url to the issue, url: ${payoutUrl}`);
    assigneeComment =
      `#### ${title} Reward \n### [ **[ CLAIM ${priceInBigNumber} ${tokenSymbol.toUpperCase()} ]** ](${payoutUrl})\n` + "```" + shortenRecipient + "```";
    const permitComments = incentivesCalculation.comments.filter((content) => {
      const permitUrlMatches = content.body.match(incentivesCalculation.claimUrlRegex);
      if (!permitUrlMatches || permitUrlMatches.length < 2) return false;
      else return true;
    });

    if (permitComments.length > 0) {
      logger.info(`Skip to generate a permit url because it has been already posted.`);
      return { error: `Permit generation disabled because it was already posted to this issue.` };
    }

    if (assigneeReward.reward[0].penaltyAmount.gt(0)) {
      await removePenalty(
        incentivesCalculation.assignee.login,
        incentivesCalculation.payload.repository.full_name,
        incentivesCalculation.paymentToken,
        incentivesCalculation.evmNetworkId.toString(),
        assigneeReward.reward[0].penaltyAmount
      );
    }

    await savePermitToDB(incentivesCalculation.assignee.id, txData);
  }

  // MERGE ALL REWARDS
  const rewards = rewardByUser.reduce((acc, curr) => {
    const existing = acc.find((item) => item.userId === curr.userId);
    if (existing) {
      existing.priceInBigNumber = existing.priceInBigNumber.add(curr.priceInBigNumber);
      // merge type by adding comma and
      existing.type = `${existing.type} and ${curr.type}`;
    } else {
      acc.push(curr);
    }
    return acc;
  }, [] as RewardByUser[]);

  // CREATE PERMIT URL FOR EACH USER
  for (const reward of rewards) {
    const { payoutUrl } = await generatePermit2Signature(reward.account, reward.priceInBigNumber, reward.issueId, reward.userId);

    if (!reward.user) {
      logger.info(`Skipping to generate a permit url for missing user. fallback: ${reward.user}`);
      continue;
    }

    switch (reward.type) {
      case "Conversation and Reviewer":
      case "Reviewer and Conversation":
        if (mergedComment === "") mergedComment = `#### ${reward.type} Rewards `;
        mergedComment = `${mergedComment}\n### [ **${reward.user}: [ CLAIM ${
          reward.priceInBigNumber
        } ${incentivesCalculation.tokenSymbol.toUpperCase()} ]** ](${payoutUrl})\n`;
        break;
      case "Conversation":
        contributorComment = `${contributorComment}\n### [ **${reward.user}: [ CLAIM ${
          reward.priceInBigNumber
        } ${incentivesCalculation.tokenSymbol.toUpperCase()} ]** ](${payoutUrl})\n`;
        contributorReward[reward.user] = payoutUrl;
        break;
      case "Reviewer":
        pullRequestReviewerComment = `${pullRequestReviewerComment}\n### [ **${reward.user}: [ CLAIM ${
          reward.priceInBigNumber
        } ${incentivesCalculation.tokenSymbol.toUpperCase()} ]** ](${payoutUrl})\n`;
        collaboratorReward[reward.user] = payoutUrl;
        break;
      default:
        break;
    }

    logger.info(`Permit url generated for contributors. reward: ${JSON.stringify(contributorReward)}`);
    logger.info(`Skipping to generate a permit url for missing accounts. fallback: ${JSON.stringify(conversationRewards.fallbackReward)}`);

    logger.info(`Permit url generated for pull request reviewers. reward: ${JSON.stringify(collaboratorReward)}`);
    logger.info(`Skipping to generate a permit url for missing accounts. fallback: ${JSON.stringify(pullRequestReviewersReward.fallbackReward)}`);
  }

  if (contributorComment && !isEmpty(contributorReward)) await addCommentToIssue(contributorComment, issueNumber);
  if (creatorComment) await addCommentToIssue(creatorComment, issueNumber);
  if (pullRequestReviewerComment && !isEmpty(collaboratorReward)) await addCommentToIssue(pullRequestReviewerComment, issueNumber);
  if (mergedComment) await addCommentToIssue(mergedComment, issueNumber);
  if (assigneeComment) await addCommentToIssue(assigneeComment + comments.promotionComment, issueNumber);

  await deleteLabel(incentivesCalculation.issueDetailed.priceLabel);
  await addLabelToIssue("Permitted");

  return { error: "" };
};
