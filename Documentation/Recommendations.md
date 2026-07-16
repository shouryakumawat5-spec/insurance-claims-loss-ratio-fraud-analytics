# Business Recommendations

Prepared as a client deliverable following the loss ratio and fraud risk analysis. Figures below are illustrative, generated from the synthetic dataset included in this repository, and are structured the way a real underwriting recommendation memo would read.

## Executive Summary

The book of business is profitable overall, but underwriting margin is being eroded by three concentrated pockets of loss: Health policies in the South region, a small cluster of agents with loss ratios more than double the network average, and a rising rate of claims that clear every fraud risk signal but are still being approved without a second review. Fixing these three issues, without changing pricing on the healthy 80 percent of the book, is projected to improve the overall loss ratio by 3 to 5 points.

## Key Findings

Health policies carry the highest average claim severity of any product line and the slowest average settlement time, which together suggest both a pricing gap and a claims handling efficiency gap.

A small number of agents, concentrated in two regions, are writing policies with loss ratios well above the tier average, which is a distribution and underwriting guideline issue rather than a claims issue.

Fraud flagged claims are not evenly distributed. They cluster in specific regions and around a subset of adjusters with lower average experience, suggesting a training gap rather than random noise.

Customers in the "High Value High Risk" segment renew at nearly the same rate as low risk customers, meaning the business is currently retaining exactly the customers it should be re-underwriting or re-pricing.

## Revenue Opportunities

Re-pricing the Health line in the highest loss region alone protects underwriting margin without touching the other three product lines.

Renewal targeting for the "High Value Low Risk" segment, who show both strong lifetime premium and low claims activity, is currently under-invested relative to their retention value.

## Cost Reduction Areas

Claims handled by adjusters in the lowest experience band take meaningfully longer to settle on average, which adds operational cost per claim independent of the payout itself.

Duplicate and orphaned records found during the data cleaning step point to a source system reconciliation gap that is quietly inflating operational reporting costs upstream of this dashboard.

## Strategic Insights

Loss ratio and fraud risk should not be managed as two separate workstreams. The regions and agents driving loss ratio overlap significantly with the regions showing elevated fraud flags, which means a single regional intervention plan can address both problems at once.

## Growth Opportunities

The "High Value Low Risk" segment is the clearest growth lever in this book of business. This group is underrepresented relative to its share of profitable premium, and a targeted acquisition and referral push aimed at this profile should expand the most profitable part of the portfolio.

## Risk Factors

Continuing to approve high fraud score claims without a mandatory secondary review creates both a direct financial risk and a regulatory reporting risk if a pattern is later identified externally rather than internally.

Agent-level loss ratio outliers that go unaddressed for multiple renewal cycles are difficult and expensive to unwind later, since the customer relationship and commission structure are already established.

## Action Plan

Introduce a mandatory secondary review trigger for any claim with a fraud score above the threshold used in the stored procedure `usp_FlagHighRiskClaims`, before payout rather than after.

Set a quarterly agent loss ratio review cadence for the bottom quartile identified in the ranking query in `Advanced_Analysis.sql`, with a defined coaching and, if needed, book transfer process.

Fund a targeted retention campaign for the "High Value Low Risk" segment, using the segmentation logic already built into the SQL layer.

Fix the upstream data reconciliation issue that is producing duplicate customer and claim records, so that future reporting does not require a manual cleaning pass.

## Closing Note

Every number in this memo traces back to a specific, reusable SQL query or view in this repository, not a one-off spreadsheet calculation. That means this analysis can be refreshed every quarter with a single script run rather than rebuilt from scratch, which is exactly the kind of durable deliverable a consulting engagement is expected to leave behind.
