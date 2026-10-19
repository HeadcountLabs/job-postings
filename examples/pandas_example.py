"""Read one table straight from Hugging Face with pandas. Needs: pip install pandas pyarrow huggingface_hub"""
import pandas as pd

companies = pd.read_parquet("hf://datasets/HeadcountLabs/job-postings/data/companies/part-0.parquet")
print(f"{len(companies):,} companies")
print(companies.nlargest(5, "job_count").to_string(index=False))

jobs = pd.read_parquet(
    "hf://datasets/HeadcountLabs/job-postings/data/jobs/part-202610-s0-0.parquet",
    columns=["job_id", "title", "employer_name", "work_arrangement", "posted_at", "posting_url"],
)
remote = jobs[jobs["work_arrangement"] == "remote"]
print(f"{len(jobs):,} jobs in this file, {len(remote):,} remote")
print(remote.head(5)[["title", "employer_name", "posted_at"]].to_string(index=False))
