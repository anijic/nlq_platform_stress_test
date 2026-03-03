# Enterprise NL2SQL Semantic Layer Stress-Test & QA

## The Business Problem
AI-powered NLQ platforms promise to let business users query data in 
plain English. But without rigorous stress-testing, these platforms 
ship with silent failure modes — wrong joins, hallucinated columns, 
and broken aggregations that produce confident-looking wrong answers.

## My Methodology: Design of Experiments (DoE)
As a Chemical Engineer, I treat NLQ validation like a process 
stress-test — not "does it work?" but "how does it fail, and why?"

I designed 30 queries across 3 complexity tiers against a 
production-grade BigQuery e-commerce sandbox:
- **Tier 1 (Basic):** Simple aggregations and filters
- **Tier 2 (Intermediate):** Multi-dimension slicing, date logic
- **Tier 3 (Advanced):** Complex joins, ratio math, NULL handling

Each query was validated against native BigQuery SQL ground truth.

## Results: 16 Failures Diagnosed Across 5 Bug Classes

| Bug Class | Description | Queries Affected |
|---|---|---|
| Entity-Locking | AI locked onto wrong entity (users vs orders) | Q5 |
| Arithmetic Myopia | Failed to compute derived ratios (AOV) | Q9 |
| Temporal Blindness | Refused to filter by non-signup dates | Q11 |
| Relationship Amnesia | Could not traverse existing foreign keys | Q25, Q29 |
| Multi-Filter Collapse | Failed when 3+ filters applied simultaneously | Q28 |

**Overall: 16/30 queries failed (53% failure rate on Tier 2–3 queries)**

## Key Deliverable
A consultant-grade Readiness Report and Root Cause Friction Log 
directly incorporated into the client's engineering roadmap.

## Tech Stack
- **Data Warehouse:** Google BigQuery
- **Validation Method:** Native SQL ground-truth comparison
- **Schema:** Star schema (Fact: orders/transactions; 
  Dims: customers, products, geography)
- **Methodology:** Design of Experiments (DoE), Root Cause Analysis

## Client Outcome
> "Super Professional — Detail Oriented, Clear Communicator, 
> Accountable for Outcomes."
> — Jedify (Upwork, February 2026, ⭐⭐⭐⭐⭐)

Built by Charles Aniji — Chemical Engineer turned Data Consultant.
