create type "public"."github_node_type" as enum ('App', 'Bot', 'CheckRun', 'CheckSuite', 'ClosedEvent', 'CodeOfConduct', 'Commit', 'CommitComment', 'CommitContributionsByRepository', 'ContributingGuidelines', 'ConvertToDraftEvent', 'CreatedCommitContribution', 'CreatedIssueContribution', 'CreatedPullRequestContribution', 'CreatedPullRequestReviewContribution', 'CreatedRepositoryContribution', 'CrossReferencedEvent', 'Discussion', 'DiscussionComment', 'Enterprise', 'EnterpriseUserAccount', 'FundingLink', 'Gist', 'Issue', 'IssueComment', 'JoinedGitHubContribution', 'Label', 'License', 'Mannequin', 'MarketplaceCategory', 'MarketplaceListing', 'MergeQueue', 'MergedEvent', 'MigrationSource', 'Milestone', 'Organization', 'PackageFile', 'Project', 'ProjectCard', 'ProjectColumn', 'ProjectV2', 'PullRequest', 'PullRequestCommit', 'PullRequestReview', 'PullRequestReviewComment', 'ReadyForReviewEvent', 'Release', 'ReleaseAsset', 'Repository', 'RepositoryContactLink', 'RepositoryTopic', 'RestrictedContribution', 'ReviewDismissedEvent', 'SecurityAdvisoryReference', 'SocialAccount', 'SponsorsListing', 'Team', 'TeamDiscussion', 'TeamDiscussionComment', 'User', 'Workflow', 'WorkflowRun', 'WorkflowRunFile');

create sequence "public"."access_id_seq";

create sequence "public"."credits_id_seq";

create sequence "public"."location_id_seq1";

create sequence "public"."new_access_id_seq";

create sequence "public"."new_debits_id_seq";

create sequence "public"."new_logs_id_seq";

create sequence "public"."new_partners_id_seq";

create sequence "public"."new_permits_id_seq";

create sequence "public"."new_tokens_id_seq";

create sequence "public"."new_tokens_network_seq";

create sequence "public"."new_users_id_seq";

create sequence "public"."new_wallets_id_seq";

create sequence "public"."partners_id_seq";

-- create sequence "public"."permits_id_seq";

create sequence "public"."settlements_id_seq";

create sequence "public"."tokens_id_seq";

create sequence "public"."unauthorized_label_changes_id_seq";

create sequence "public"."users_id_seq";

create sequence "public"."wallets_id_seq";

drop policy "Enable read access for frontend" on "public"."permits";

drop function if exists "public"."add_penalty"(_username text, _repository_name text, _network_id text, _token_address text, _penalty_amount text);

drop function if exists "public"."remove_penalty"(_username text, _repository_name text, _network_id text, _token_address text, _penalty_amount text);

alter table "public"."access" drop constraint "access_pkey";

alter table "public"."debits" drop constraint "debits_pkey";

alter table "public"."issues" drop constraint "issues_pkey";

alter table "public"."label_changes" drop constraint "label_changes_pkey";

alter table "public"."logs" drop constraint "logs_pkey";

alter table "public"."multiplier" drop constraint "multiplier_pkey";

alter table "public"."penalty" drop constraint "penalty_pkey";

alter table "public"."permits" drop constraint "permits_pkey";

alter table "public"."users" drop constraint "users_pkey";

alter table "public"."wallets" drop constraint "wallets_pkey";

drop index if exists "public"."access_pkey";

drop index if exists "public"."debits_pkey";

drop index if exists "public"."idx_timestamp";

drop index if exists "public"."issues_pkey";

drop index if exists "public"."label_changes_pkey";

drop index if exists "public"."logs_pkey";

drop index if exists "public"."multiplier_pkey";

drop index if exists "public"."penalty_pkey";

drop index if exists "public"."permits_pkey";

drop index if exists "public"."users_pkey";

drop index if exists "public"."wallets_pkey";

drop table "public"."issues";

drop table "public"."label_changes";

drop table "public"."multiplier";

drop table "public"."penalty";

drop table "public"."weekly";

create table "public"."credits" (
    "id" integer not null default nextval('credits_id_seq'::regclass),
    "created" timestamp with time zone not null default now(),
    "updated" timestamp with time zone,
    "amount" numeric not null,
    "permit_id" integer,
    "location_id" integer
);


create table "public"."labels" (
    "id" integer not null default nextval('unauthorized_label_changes_id_seq'::regclass),
    "created" timestamp with time zone not null default now(),
    "updated" timestamp with time zone default now(),
    "label_from" text,
    "label_to" text,
    "authorized" boolean,
    "location_id" integer
);


create table "public"."locations" (
    "id" integer not null default nextval('location_id_seq1'::regclass),
    "node_id" character varying(255),
    "node_type" character varying(255),
    "updated" timestamp with time zone,
    "created" timestamp with time zone not null default now(),
    "node_url" text,
    "user_id" integer,
    "repository_id" integer,
    "organization_id" integer,
    "comment_id" integer,
    "issue_id" integer
);


create table "public"."partners" (
    "id" integer not null default nextval('partners_id_seq'::regclass),
    "created" timestamp with time zone not null default now(),
    "updated" timestamp with time zone,
    "wallet_id" integer,
    "location_id" integer
);


create table "public"."settlements" (
    "id" integer not null default nextval('settlements_id_seq'::regclass),
    "created" timestamp with time zone not null default now(),
    "updated" timestamp with time zone,
    "user_id" integer not null,
    "location_id" integer,
    "credit_id" integer,
    "debit_id" integer
);


create table "public"."tokens" (
    "id" integer not null default nextval('tokens_id_seq'::regclass),
    "created" timestamp with time zone not null default now(),
    "updated" timestamp with time zone,
    "network" smallint not null default nextval('new_tokens_network_seq'::regclass),
    "address" character(42) not null,
    "location_id" integer
);


alter table "public"."access" drop column "created_at";

alter table "public"."access" drop column "multiplier_access";

alter table "public"."access" drop column "price_access";

alter table "public"."access" drop column "priority_access";

alter table "public"."access" drop column "repository";

alter table "public"."access" drop column "time_access";

alter table "public"."access" drop column "updated_at";

alter table "public"."access" drop column "user_name";

alter table "public"."access" add column "created" timestamp with time zone not null default now();

alter table "public"."access" add column "id" integer not null default nextval('access_id_seq'::regclass);

alter table "public"."access" add column "labels" json;

alter table "public"."access" add column "location_id" integer;

alter table "public"."access" add column "multiplier" smallint not null default '1'::smallint;

alter table "public"."access" add column "multiplier_reason" text;

alter table "public"."access" add column "updated" timestamp with time zone;

alter table "public"."access" add column "user_id" integer not null;

alter table "public"."access" disable row level security;

alter table "public"."debits" drop column "created_at";

alter table "public"."debits" drop column "updated_at";

alter table "public"."debits" add column "created" timestamp with time zone not null default now();

alter table "public"."debits" add column "location_id" integer;

alter table "public"."debits" add column "token_id" integer;

alter table "public"."debits" add column "updated" timestamp with time zone;

alter table "public"."debits" alter column "amount" set data type numeric using "amount"::numeric;

alter table "public"."logs" drop column "comment_id";

alter table "public"."logs" drop column "issue_number";

alter table "public"."logs" drop column "log_message";

alter table "public"."logs" drop column "org_name";

alter table "public"."logs" drop column "repo_name";

alter table "public"."logs" drop column "timestamp";

alter table "public"."logs" add column "created" timestamp with time zone not null default now();

alter table "public"."logs" add column "location_id" integer;

alter table "public"."logs" add column "log" text not null;

alter table "public"."logs" add column "metadata" jsonb;

alter table "public"."logs" add column "updated" timestamp with time zone;

alter table "public"."logs" alter column "level" set data type text using "level"::text;

alter table "public"."logs" disable row level security;

alter table "public"."permits" drop column "contributor_id";

alter table "public"."permits" drop column "contributor_wallet";

alter table "public"."permits" drop column "created_at";

alter table "public"."permits" drop column "evm_network_id";

alter table "public"."permits" drop column "issue_id";

alter table "public"."permits" drop column "organization_id";

alter table "public"."permits" drop column "partner_wallet";

alter table "public"."permits" drop column "payout_amount";

alter table "public"."permits" drop column "repository_id";

alter table "public"."permits" drop column "token_address";

alter table "public"."permits" add column "amount" text not null;

alter table "public"."permits" add column "beneficiary_id" integer not null;

alter table "public"."permits" add column "created" timestamp with time zone not null default now();

alter table "public"."permits" add column "location_id" integer;

alter table "public"."permits" add column "partner_id" integer;

alter table "public"."permits" add column "token_id" integer;

alter table "public"."permits" add column "transaction" character(66);

alter table "public"."permits" add column "updated" timestamp with time zone;

-- alter table "public"."permits" alter column "id" set default nextval('permits_id_seq'::regclass);

alter table "public"."permits" alter column "id" drop identity;

alter table "public"."permits" alter column "id" set data type integer using "id"::integer;

alter table "public"."permits" alter column "signature" set data type character(132) using "signature"::character(132);

alter table "public"."permits" disable row level security;

alter table "public"."users" drop column "bio";

alter table "public"."users" drop column "blog";

alter table "public"."users" drop column "company";

alter table "public"."users" drop column "contributions";

alter table "public"."users" drop column "created_at";

alter table "public"."users" drop column "email";

alter table "public"."users" drop column "followers";

alter table "public"."users" drop column "following";

alter table "public"."users" drop column "percent_code_reviews";

alter table "public"."users" drop column "percent_commits";

alter table "public"."users" drop column "percent_issues";

alter table "public"."users" drop column "percent_pull_requests";

alter table "public"."users" drop column "public_repos";

alter table "public"."users" drop column "twitter_username";

alter table "public"."users" drop column "updated_at";

alter table "public"."users" drop column "user_location";

alter table "public"."users" drop column "user_login";

alter table "public"."users" drop column "user_name";

alter table "public"."users" drop column "user_type";

alter table "public"."users" drop column "wallet_address";

alter table "public"."users" add column "created" timestamp with time zone not null default now();

alter table "public"."users" add column "id" integer not null default nextval('users_id_seq'::regclass);

alter table "public"."users" add column "location_id" integer;

alter table "public"."users" add column "updated" timestamp with time zone;

alter table "public"."users" add column "wallet_id" integer;

alter table "public"."users" disable row level security;

alter table "public"."wallets" drop column "created_at";

alter table "public"."wallets" drop column "updated_at";

alter table "public"."wallets" drop column "user_name";

alter table "public"."wallets" drop column "wallet_address";

alter table "public"."wallets" add column "address" character(42);

alter table "public"."wallets" add column "created" timestamp with time zone not null default now();

alter table "public"."wallets" add column "id" integer not null default nextval('wallets_id_seq'::regclass);

alter table "public"."wallets" add column "location_id" integer;

alter table "public"."wallets" add column "updated" timestamp with time zone;

alter table "public"."wallets" disable row level security;

alter sequence "public"."credits_id_seq" owned by "public"."credits"."id";

alter sequence "public"."location_id_seq1" owned by "public"."locations"."id";

alter sequence "public"."new_access_id_seq" owned by "public"."access"."id";

alter sequence "public"."new_debits_id_seq" owned by "public"."debits"."id";

alter sequence "public"."new_logs_id_seq" owned by "public"."logs"."id";

alter sequence "public"."new_partners_id_seq" owned by "public"."partners"."id";

alter sequence "public"."new_permits_id_seq" owned by "public"."permits"."id";

alter sequence "public"."new_tokens_id_seq" owned by "public"."tokens"."id";

alter sequence "public"."new_tokens_network_seq" owned by "public"."tokens"."network";

alter sequence "public"."new_users_id_seq" owned by "public"."users"."id";

alter sequence "public"."new_wallets_id_seq" owned by "public"."wallets"."id";

alter sequence "public"."settlements_id_seq" owned by "public"."settlements"."id";

alter sequence "public"."unauthorized_label_changes_id_seq" owned by "public"."labels"."id";

alter sequence "public"."debits_id_seq" owned by none;

alter sequence "public"."logs_id_seq" owned by none;

drop sequence if exists "public"."issues_id_seq";

drop sequence if exists "public"."label_changes_id_seq";

drop type "public"."issue_status";

drop extension if exists "pg_cron";

CREATE UNIQUE INDEX credits_pkey ON public.credits USING btree (id);

CREATE UNIQUE INDEX location_node_id_node_type_key ON public.locations USING btree (node_id, node_type);

CREATE UNIQUE INDEX location_pkey1 ON public.locations USING btree (id);

CREATE UNIQUE INDEX location_unique_node ON public.locations USING btree (node_id, node_type);

CREATE UNIQUE INDEX new_access_pkey ON public.access USING btree (id);

CREATE UNIQUE INDEX new_debits_pkey ON public.debits USING btree (id);

CREATE UNIQUE INDEX new_logs_pkey ON public.logs USING btree (id);

CREATE UNIQUE INDEX new_partners_pkey ON public.partners USING btree (id);

CREATE UNIQUE INDEX new_permits_pkey ON public.permits USING btree (id);

CREATE UNIQUE INDEX new_tokens_pkey ON public.tokens USING btree (id);

CREATE UNIQUE INDEX new_users_pkey ON public.users USING btree (id);

CREATE UNIQUE INDEX new_wallets_pkey ON public.wallets USING btree (id);

CREATE UNIQUE INDEX new_wallets_wallet_key ON public.wallets USING btree (address);

CREATE UNIQUE INDEX partners_wallet_key ON public.partners USING btree (wallet_id);

CREATE UNIQUE INDEX permits_nonce_key ON public.permits USING btree (nonce);

CREATE UNIQUE INDEX permits_signature_key ON public.permits USING btree (signature);

CREATE UNIQUE INDEX permits_transaction_key ON public.permits USING btree (transaction);

CREATE UNIQUE INDEX settlements_pkey ON public.settlements USING btree (id);

CREATE UNIQUE INDEX unauthorized_label_changes_pkey ON public.labels USING btree (id);

alter table "public"."access" add constraint "new_access_pkey" PRIMARY KEY using index "new_access_pkey";

alter table "public"."credits" add constraint "credits_pkey" PRIMARY KEY using index "credits_pkey";

alter table "public"."debits" add constraint "new_debits_pkey" PRIMARY KEY using index "new_debits_pkey";

alter table "public"."labels" add constraint "unauthorized_label_changes_pkey" PRIMARY KEY using index "unauthorized_label_changes_pkey";

alter table "public"."locations" add constraint "location_pkey1" PRIMARY KEY using index "location_pkey1";

alter table "public"."logs" add constraint "new_logs_pkey" PRIMARY KEY using index "new_logs_pkey";

alter table "public"."partners" add constraint "new_partners_pkey" PRIMARY KEY using index "new_partners_pkey";

alter table "public"."permits" add constraint "new_permits_pkey" PRIMARY KEY using index "new_permits_pkey";

alter table "public"."settlements" add constraint "settlements_pkey" PRIMARY KEY using index "settlements_pkey";

alter table "public"."tokens" add constraint "new_tokens_pkey" PRIMARY KEY using index "new_tokens_pkey";

alter table "public"."users" add constraint "new_users_pkey" PRIMARY KEY using index "new_users_pkey";

alter table "public"."wallets" add constraint "new_wallets_pkey" PRIMARY KEY using index "new_wallets_pkey";

alter table "public"."access" add constraint "access_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) not valid;

alter table "public"."access" validate constraint "access_user_id_fkey";

alter table "public"."access" add constraint "fk_access_location" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE not valid;

alter table "public"."access" validate constraint "fk_access_location";

alter table "public"."credits" add constraint "credits_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) not valid;

alter table "public"."credits" validate constraint "credits_location_id_fkey";

alter table "public"."credits" add constraint "credits_permit_id_fkey" FOREIGN KEY (permit_id) REFERENCES permits(id) not valid;

alter table "public"."credits" validate constraint "credits_permit_id_fkey";

alter table "public"."debits" add constraint "debits_token_id_fkey" FOREIGN KEY (token_id) REFERENCES tokens(id) not valid;

alter table "public"."debits" validate constraint "debits_token_id_fkey";

alter table "public"."debits" add constraint "fk_debits_location" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE not valid;

alter table "public"."debits" validate constraint "fk_debits_location";

alter table "public"."labels" add constraint "labels_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) not valid;

alter table "public"."labels" validate constraint "labels_location_id_fkey";

alter table "public"."locations" add constraint "location_node_id_node_type_key" UNIQUE using index "location_node_id_node_type_key";

alter table "public"."locations" add constraint "location_node_type_check1" CHECK (((node_type)::text = ANY (ARRAY[('App'::character varying)::text, ('Bot'::character varying)::text, ('CheckRun'::character varying)::text, ('CheckSuite'::character varying)::text, ('ClosedEvent'::character varying)::text, ('CodeOfConduct'::character varying)::text, ('Commit'::character varying)::text, ('CommitComment'::character varying)::text, ('CommitContributionsByRepository'::character varying)::text, ('ContributingGuidelines'::character varying)::text, ('ConvertToDraftEvent'::character varying)::text, ('CreatedCommitContribution'::character varying)::text, ('CreatedIssueContribution'::character varying)::text, ('CreatedPullRequestContribution'::character varying)::text, ('CreatedPullRequestReviewContribution'::character varying)::text, ('CreatedRepositoryContribution'::character varying)::text, ('CrossReferencedEvent'::character varying)::text, ('Discussion'::character varying)::text, ('DiscussionComment'::character varying)::text, ('Enterprise'::character varying)::text, ('EnterpriseUserAccount'::character varying)::text, ('FundingLink'::character varying)::text, ('Gist'::character varying)::text, ('Issue'::character varying)::text, ('IssueComment'::character varying)::text, ('JoinedGitHubContribution'::character varying)::text, ('Label'::character varying)::text, ('License'::character varying)::text, ('Mannequin'::character varying)::text, ('MarketplaceCategory'::character varying)::text, ('MarketplaceListing'::character varying)::text, ('MergeQueue'::character varying)::text, ('MergedEvent'::character varying)::text, ('MigrationSource'::character varying)::text, ('Milestone'::character varying)::text, ('Organization'::character varying)::text, ('PackageFile'::character varying)::text, ('Project'::character varying)::text, ('ProjectCard'::character varying)::text, ('ProjectColumn'::character varying)::text, ('ProjectV2'::character varying)::text, ('PullRequest'::character varying)::text, ('PullRequestCommit'::character varying)::text, ('PullRequestReview'::character varying)::text, ('PullRequestReviewComment'::character varying)::text, ('ReadyForReviewEvent'::character varying)::text, ('Release'::character varying)::text, ('ReleaseAsset'::character varying)::text, ('Repository'::character varying)::text, ('RepositoryContactLink'::character varying)::text, ('RepositoryTopic'::character varying)::text, ('RestrictedContribution'::character varying)::text, ('ReviewDismissedEvent'::character varying)::text, ('SecurityAdvisoryReference'::character varying)::text, ('SocialAccount'::character varying)::text, ('SponsorsListing'::character varying)::text, ('Team'::character varying)::text, ('TeamDiscussion'::character varying)::text, ('TeamDiscussionComment'::character varying)::text, ('User'::character varying)::text, ('Workflow'::character varying)::text, ('WorkflowRun'::character varying)::text, ('WorkflowRunFile'::character varying)::text]))) not valid;

alter table "public"."locations" validate constraint "location_node_type_check1";

alter table "public"."locations" add constraint "location_unique_node" UNIQUE using index "location_unique_node";

alter table "public"."locations" add constraint "locations_node_url_check" CHECK ((node_url ~~ 'https://github.com/%'::text)) not valid;

alter table "public"."locations" validate constraint "locations_node_url_check";

alter table "public"."logs" add constraint "fk_logs_location" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE not valid;

alter table "public"."logs" validate constraint "fk_logs_location";

alter table "public"."partners" add constraint "fk_partners_location" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE not valid;

alter table "public"."partners" validate constraint "fk_partners_location";

alter table "public"."partners" add constraint "partners_wallet_id_fkey" FOREIGN KEY (wallet_id) REFERENCES wallets(id) not valid;

alter table "public"."partners" validate constraint "partners_wallet_id_fkey";

alter table "public"."partners" add constraint "partners_wallet_key" UNIQUE using index "partners_wallet_key";

alter table "public"."permits" add constraint "fk_permits_location" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE not valid;

alter table "public"."permits" validate constraint "fk_permits_location";

alter table "public"."permits" add constraint "permits_beneficiary_id_fkey" FOREIGN KEY (beneficiary_id) REFERENCES users(id) not valid;

alter table "public"."permits" validate constraint "permits_beneficiary_id_fkey";

alter table "public"."permits" add constraint "permits_nonce_key" UNIQUE using index "permits_nonce_key";

alter table "public"."permits" add constraint "permits_partner_id_fkey" FOREIGN KEY (partner_id) REFERENCES partners(id) not valid;

alter table "public"."permits" validate constraint "permits_partner_id_fkey";

alter table "public"."permits" add constraint "permits_signature_key" UNIQUE using index "permits_signature_key";

alter table "public"."permits" add constraint "permits_token_fkey" FOREIGN KEY (token_id) REFERENCES tokens(id) not valid;

alter table "public"."permits" validate constraint "permits_token_fkey";

alter table "public"."permits" add constraint "permits_transaction_key" UNIQUE using index "permits_transaction_key";

alter table "public"."settlements" add constraint "fk_settlements_location" FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE not valid;

alter table "public"."settlements" validate constraint "fk_settlements_location";

alter table "public"."settlements" add constraint "settlements_credit_id_fkey" FOREIGN KEY (credit_id) REFERENCES credits(id) not valid;

alter table "public"."settlements" validate constraint "settlements_credit_id_fkey";

alter table "public"."settlements" add constraint "settlements_debit_id_fkey" FOREIGN KEY (debit_id) REFERENCES debits(id) not valid;

alter table "public"."settlements" validate constraint "settlements_debit_id_fkey";

alter table "public"."settlements" add constraint "settlements_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) not valid;

alter table "public"."settlements" validate constraint "settlements_user_id_fkey";

alter table "public"."tokens" add constraint "tokens_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) not valid;

alter table "public"."tokens" validate constraint "tokens_location_id_fkey";

alter table "public"."users" add constraint "users_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) not valid;

alter table "public"."users" validate constraint "users_location_id_fkey";

alter table "public"."users" add constraint "users_wallet_id_fkey" FOREIGN KEY (wallet_id) REFERENCES wallets(id) not valid;

alter table "public"."users" validate constraint "users_wallet_id_fkey";

alter table "public"."wallets" add constraint "new_wallets_wallet_key" UNIQUE using index "new_wallets_wallet_key";

alter table "public"."wallets" add constraint "wallets_address_check" CHECK ((length(address) = 42)) not valid;

alter table "public"."wallets" validate constraint "wallets_address_check";

alter table "public"."wallets" add constraint "wallets_location_id_fkey" FOREIGN KEY (location_id) REFERENCES locations(id) not valid;

alter table "public"."wallets" validate constraint "wallets_location_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.updated()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
    NEW.updated = NOW();
    RETURN NEW;
END;$function$
;

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.access FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.credits FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.debits FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.labels FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.locations FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.logs FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.partners FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.permits FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.settlements FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.tokens FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION updated();

CREATE TRIGGER handle_updated_trigger BEFORE UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION updated();


