import { Octokit } from "octokit";

async function main() {
  const octokit = new Octokit({ auth: "REDACTED" });

  // get issue info
  const issue = await octokit.rest.issues.get({
    owner: "rndquu",
    repo: "bounty-bot",
    issue_number: 1,
  });

  console.log(issue.data);
}

main();
