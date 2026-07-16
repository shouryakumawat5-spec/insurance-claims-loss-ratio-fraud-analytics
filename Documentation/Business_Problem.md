# Business Problem

## Client Context

A mid sized multi line insurance carrier, writing Auto, Home, Life and Health policies across fifteen states, is heading into its annual underwriting strategy review. The Chief Underwriting Officer has flagged three concerns going into the meeting.

The combined loss ratio has been drifting upward over the last two fiscal years, and nobody can say with confidence which regions, agents, or policy types are driving it.

A small but growing number of claims look statistically unusual, high value, fast settled, submitted by a handful of repeat policy holders, and the special investigations team is stretched too thin to review every case manually.

Renewal rates vary widely by customer segment and nobody has connected renewal behavior back to loss experience, so pricing and retention decisions are being made independently of each other.

## The Ask

Build a single source of truth that lets underwriting, claims, and distribution leadership answer three questions without waiting on a monthly PDF report.

Where is the business losing money, broken down by region, agent, and policy type.

Which claims deserve a second look before they are paid out.

Which customer segments are worth protecting with better pricing or service, and which are structurally unprofitable.

## Why This Matters Financially

A one point improvement in loss ratio across this book of business is worth real underwriting margin. A carrier this size typically writes tens of millions of dollars in annual premium, so even small improvements in fraud detection and renewal targeting translate directly into profit, not just a nicer dashboard.

## Scope Of This Engagement

This project covers the full analytics lifecycle end to end. Raw claims, policy, customer, agent and adjuster data is extracted, cleaned, and modeled into a star schema in SQL. Loss ratio, fraud risk, and renewal KPIs are calculated directly in SQL, and a Power BI dashboard is built on top to give leadership a self service view they can slice by region, product, agent, and time period without needing a new SQL query every time a question comes up.

## Out Of Scope

This project does not build a predictive fraud model. It builds a rules based fraud risk flagging system using SQL logic, comparable to a first pass triage tool a carrier would use before escalating to a full investigations team. No Python or machine learning libraries are used anywhere in this project, by design, to keep the deliverable fully reproducible with only SQL and Power BI.
