-- Top 10 employers by number of jobs (companies table, 1.5 MB)
SELECT employer_name, job_count
FROM 'hf://datasets/HeadcountLabs/job-postings/data/companies/part-0.parquet'
ORDER BY job_count DESC
LIMIT 10;

-- US jobs by state (job_locations table, all 8 files)
SELECT region, count(DISTINCT job_id) AS jobs
FROM 'hf://datasets/HeadcountLabs/job-postings/data/job_locations/*.parquet'
WHERE country = 'US' AND region IS NOT NULL
GROUP BY region
ORDER BY jobs DESC
LIMIT 10;

-- Work arrangement of jobs first posted in October 2026 (one of the seven October files)
SELECT coalesce(work_arrangement, 'not stated') AS work_arrangement, count(*) AS jobs
FROM 'hf://datasets/HeadcountLabs/job-postings/data/jobs/part-202610-s0-0.parquet'
GROUP BY 1
ORDER BY jobs DESC;

-- Pay published on October 2026 postings, by pay interval (one file)
SELECT coalesce(pay_interval, 'no pay published') AS pay_interval, count(*) AS postings,
       round(median(pay_min)) AS median_pay_min
FROM 'hf://datasets/HeadcountLabs/job-postings/data/postings/part-202610-s0-0.parquet'
GROUP BY 1
ORDER BY postings DESC;
