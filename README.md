<p align="center">
  <a href="https://headcountlabs.com"><img src="https://raw.githubusercontent.com/HeadcountLabs/.github/main/headcountlabs-icon-512.png" alt="Headcount Labs" width="96" height="96"></a>
</p>

# Headcount Labs Job Postings

An open dataset of **8,367,463 job postings** read straight from employers' own career pages and hiring systems,
plus a live API and MCP server that serve the same jobs, updated daily.

- **Dataset:** [huggingface.co/datasets/HeadcountLabs/job-postings](https://huggingface.co/datasets/HeadcountLabs/job-postings), CC BY 4.0, 8.9 GB of Parquet.
- **Live API:** [headcountlabs.com/docs](https://headcountlabs.com/docs/), free for the first 100,000 records each month.
- **MCP server for AI agents:** [headcountlabs.com/mcp](https://headcountlabs.com/mcp/), with a no-account endpoint.
- **Website:** [headcountlabs.com](https://headcountlabs.com).

Star this repository to follow new releases of the dataset.

## What Headcount Labs is

Headcount Labs reads the public job boards of employers on Workday, Greenhouse, Lever, iCIMS, SmartRecruiters,
Oracle, SAP SuccessFactors and more than 100 other hiring platforms, plus company career sites and government job
exchanges. Copies of the same opening on several boards are merged into one job, and each job keeps a link to every
original posting. Each field says whether the employer published it or we derived it.

The live API counted **8,365,616 open jobs** on 2026-10-19 at 5:24 PM ET (`GET /v1/jobs/count`).

## The dataset

The full dataset lives on Hugging Face, not in this repository. This repository holds the documentation, example
queries and a 1,000-row sample.

| Table | One row per | Rows |
| --- | --- | --- |
| `jobs` | job, after merging copies | 8,367,463 |
| `postings` | listing of a job on one source | 9,987,268 |
| `job_locations` | job location (country, region, city, zip, metro area) | 9,699,125 |
| `companies` | company ID seen on a job | 47,621 |

Snapshot taken on 2026-10-19 between 12:47 PM and 4:43 PM ET. It is a one-time full snapshot of every job the
public API served at that time. Job description text is not included; every posting links to the original listing.

### Schema summary

The full column list is in [SCHEMA.md](https://huggingface.co/datasets/HeadcountLabs/job-postings/blob/main/SCHEMA.md).
The columns you will use most:

| Table | Column | Meaning |
| --- | --- | --- |
| `jobs` | `job_id` | Stable job ID. Join key to `postings` and `job_locations`. |
| `jobs` | `title`, `employer_name` | Title and employer as the employer published them. |
| `jobs` | `work_arrangement` | `remote`, `hybrid` or `in_person` when stated, else null. |
| `jobs` | `posted_at` | Earliest posting date of the job. Files are grouped by its month. |
| `jobs` | `currentness` | `current`, `uncertain` or `not_current`. |
| `jobs` | `posting_url` | Link to an original listing. |
| `postings` | `pay_min`, `pay_max`, `pay_currency`, `pay_interval` | Pay as published, not converted. |
| `postings` | `employment_type`, `source_type`, `source_class` | Employment type as stated, the platform, and the kind of source. |
| `postings` | `application_url` | Where to apply. |
| `job_locations` | `country`, `region`, `locality`, `zip`, `cbsa_code` | ISO country, ISO 3166-2 region such as `US-TX`, city, postal code, US metro area code. |
| `companies` | `employer_name`, `job_count` | Most common employer name for the company and its number of jobs. |

Columns ending in `_json` hold the value with its origin: `{"state": "known", "value": ...}` when the source
published it, `derived` when we computed it, `source_omitted` when the source does not publish the field.

### Sample

[`sample/jobs-sample-1000.csv`](sample/jobs-sample-1000.csv) has 1,000 random jobs first posted in October 2026
(flat columns from `jobs`), so you can see the shape before you download anything.

## Example queries

Each query below reads the Parquet files straight from Hugging Face. They were run on 2026-10-19 with DuckDB 1.4.1,
pandas 2.3.3 and datasets 5.0.0; the results shown are from that run. The SQL is in [`examples/queries.sql`](examples/queries.sql)
and the pandas script in [`examples/pandas_example.py`](examples/pandas_example.py).

**Top employers by number of jobs** (DuckDB):

```sql
SELECT employer_name, job_count
FROM 'hf://datasets/HeadcountLabs/job-postings/data/companies/part-0.parquet'
ORDER BY job_count DESC
LIMIT 10;
```

| employer_name | job_count |
| --- | ---: |
| H&R Block | 41,500 |
| Domino's | 27,985 |
| The Kroger Co. | 26,865 |
| Walgreens | 21,434 |
| Marriott | 20,904 |

**US jobs by state** (DuckDB, all 8 location files, about 25 seconds):

```sql
SELECT region, count(DISTINCT job_id) AS jobs
FROM 'hf://datasets/HeadcountLabs/job-postings/data/job_locations/*.parquet'
WHERE country = 'US' AND region IS NOT NULL
GROUP BY region
ORDER BY jobs DESC
LIMIT 10;
```

| region | jobs |
| --- | ---: |
| US-CA | 459,517 |
| US-TX | 437,948 |
| US-FL | 283,916 |
| US-NY | 265,725 |
| US-OH | 192,004 |

**Posted pay on October 2026 postings, by pay interval** (DuckDB, one of the eight October files):

```sql
SELECT coalesce(pay_interval, 'no pay published') AS pay_interval, count(*) AS postings,
       round(median(pay_min)) AS median_pay_min
FROM 'hf://datasets/HeadcountLabs/job-postings/data/postings/part-202610-s0-0.parquet'
GROUP BY 1
ORDER BY postings DESC;
```

| pay_interval | postings | median_pay_min |
| --- | ---: | ---: |
| no pay published | 208,753 | |
| hour | 64,318 | 19 |
| year | 38,798 | 82,500 |
| month | 12,163 | 39,000 |
| unknown | 11,920 | 49,590 |

Pay is in the currency the employer used, so the medians mix currencies.

**Remote jobs with pandas** (needs `pip install pandas pyarrow huggingface_hub`):

```python
import pandas as pd

jobs = pd.read_parquet(
    "hf://datasets/HeadcountLabs/job-postings/data/jobs/part-202610-s0-0.parquet",
    columns=["job_id", "title", "employer_name", "work_arrangement", "posted_at", "posting_url"],
)
remote = jobs[jobs["work_arrangement"] == "remote"]
print(f"{len(jobs):,} jobs in this file, {len(remote):,} remote")
# 315,523 jobs in this file, 6,995 remote
```

**Streaming with Hugging Face `datasets`** (no full download):

```python
from datasets import load_dataset

jobs = load_dataset("HeadcountLabs/job-postings", "jobs", split="train", streaming=True)
for row in jobs.take(3):
    print(row["title"], "|", row["employer_name"], "|", row["posted_at"])
```

## Live API

The dataset is a snapshot. The API serves the same jobs live, with job descriptions and search by title, place,
employer, pay and date. Create a free key at [api.headcountlabs.com/data/signup](https://api.headcountlabs.com/data/signup), then:

```bash
curl "https://api.headcountlabs.com/v1/jobs?q=registered+nurse&state=NY&limit=25" \
  --header "Authorization: Bearer $HEADCOUNTLABS_API_KEY"

curl "https://api.headcountlabs.com/v1/jobs/count" \
  --header "Authorization: Bearer $HEADCOUNTLABS_API_KEY"
```

Every organization gets 100,000 records free each calendar month, with no card. After that, records cost a flat
$0.01 per 1,000. Counts are free. Details: [headcountlabs.com/pricing](https://headcountlabs.com/pricing/).

## MCP server

Claude, ChatGPT, Codex, Cursor and other MCP clients can search, count and read jobs through the hosted MCP server.
Try it with no account:

```bash
claude mcp add --transport http headcountlabs-public https://api.headcountlabs.com/mcp/public
```

Or count every open job with one request:

```bash
curl -s https://api.headcountlabs.com/mcp/public \
  -H "content-type: application/json" -H "accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"count_jobs","arguments":{}}}'
```

The signed-in endpoint is `https://api.headcountlabs.com/mcp`. Setup for each client:
[headcountlabs.com/mcp](https://headcountlabs.com/mcp/) and the
[headcountlabs-mcp](https://github.com/HeadcountLabs/headcountlabs-mcp) repository. For Claude Code there is also a
[plugin](https://github.com/HeadcountLabs/claude-plugin).

## Job lists on GitHub

Open job lists built every morning from the API. Each job was still listed on the employer's own board within the
past three days, and closed jobs drop off at the next update.

- **Internships and new grad:** [Software engineering internships](https://github.com/HeadcountLabs/software-engineering-internships) · [Data, AI and ML internships](https://github.com/HeadcountLabs/data-science-ai-internships) · [Engineering internships](https://github.com/HeadcountLabs/engineering-internships) · [Business and finance internships](https://github.com/HeadcountLabs/business-finance-internships) · [All internships](https://github.com/HeadcountLabs/internships) · [New grad software engineer](https://github.com/HeadcountLabs/new-grad-software-engineer-jobs) · [Entry-level jobs](https://github.com/HeadcountLabs/entry-level-jobs) · [Entry-level data analyst](https://github.com/HeadcountLabs/entry-level-data-analyst-jobs)
- **Remote:** [All remote jobs](https://github.com/HeadcountLabs/remote-jobs) · [Software engineering](https://github.com/HeadcountLabs/remote-software-engineer-jobs) · [Data](https://github.com/HeadcountLabs/remote-data-jobs) · [Product management](https://github.com/HeadcountLabs/remote-product-manager-jobs) · [Marketing](https://github.com/HeadcountLabs/remote-marketing-jobs) · [Sales](https://github.com/HeadcountLabs/remote-sales-jobs) · [Customer support](https://github.com/HeadcountLabs/remote-customer-support-jobs) · [Healthcare](https://github.com/HeadcountLabs/remote-healthcare-jobs) · [Finance and accounting](https://github.com/HeadcountLabs/remote-finance-accounting-jobs)
- **By role:** [Tech and software](https://github.com/HeadcountLabs/tech-jobs) · [AI and ML engineer](https://github.com/HeadcountLabs/ai-ml-engineer-jobs) · [Data engineer](https://github.com/HeadcountLabs/data-engineer-jobs) · [Cybersecurity](https://github.com/HeadcountLabs/cybersecurity-jobs) · [Product manager](https://github.com/HeadcountLabs/product-manager-jobs) · [Registered nurse](https://github.com/HeadcountLabs/registered-nurse-jobs) · [Software jobs paying $200k+](https://github.com/HeadcountLabs/high-paying-software-jobs) · [Jobs with salary listed](https://github.com/HeadcountLabs/pay-transparency-jobs)
- **By city (tech):** [Bay Area](https://github.com/HeadcountLabs/bay-area-tech-jobs) · [New York](https://github.com/HeadcountLabs/new-york-tech-jobs) · [Seattle](https://github.com/HeadcountLabs/seattle-tech-jobs) · [Austin](https://github.com/HeadcountLabs/austin-tech-jobs) · [Boston](https://github.com/HeadcountLabs/boston-tech-jobs) · [Los Angeles](https://github.com/HeadcountLabs/los-angeles-tech-jobs) · [Washington, DC](https://github.com/HeadcountLabs/washington-dc-tech-jobs)

## How to cite

Credit "Headcount Labs (https://headcountlabs.com)" when you use the data. GitHub's "Cite this repository" button
reads [`CITATION.cff`](CITATION.cff). BibTeX:

```bibtex
@misc{headcountlabs_job_postings_2026,
  author       = {{Headcount Labs}},
  title        = {Headcount Labs Job Postings},
  year         = {2026},
  month        = oct,
  publisher    = {Hugging Face},
  howpublished = {\url{https://huggingface.co/datasets/HeadcountLabs/job-postings}},
  note         = {Snapshot of 2026-10-19, CC BY 4.0}
}
```

## License

The dataset and the sample in this repository are licensed under [CC BY 4.0](LICENSE). The example code in
[`examples/`](examples/) is under the [MIT License](examples/LICENSE). Job posting text, employer names and logos
belong to the employers that published them.

Questions, corrections or takedown requests: [headcountlabs.com/contact](https://headcountlabs.com/contact/) or
support@headcountlabs.com.
