# Executive Summary Deck Outline

Use this as the slide by slide script for a five to seven minute walkthrough of the project, in an interview or a portfolio review. Each heading below is one slide.

**Slide 1, Title.** Insurance Claims Loss Ratio and Fraud Risk Analytics. Subtitle: An end to end SQL and Power BI engagement.

**Slide 2, The Business Problem.** Loss ratio drifting upward, no visibility into where. Rising fraud exposure with a stretched investigations team. Renewal and pricing decisions made independently of loss experience. Pull directly from Business_Problem.md.

**Slide 3, Approach.** Five stage pipeline: raw extract, SQL cleaning, star schema transformation, KPI and advanced SQL analysis, Power BI executive dashboard. Show the architecture diagram from the README.

**Slide 4, Data Model.** Show the ER diagram. Call out the star schema: two fact tables, four dimension tables.

**Slide 5, Key Finding 1.** Health policies in the South region are the single largest loss ratio driver. Show the loss ratio by region and policy type chart.

**Slide 6, Key Finding 2.** A concentrated cluster of agents and adjusters is driving both loss ratio and fraud exposure. Show the agent ranking window function output.

**Slide 7, Key Finding 3.** The business is retaining exactly the wrong customers. Show the value versus risk segmentation matrix.

**Slide 8, The Dashboard.** Walk through the Executive Summary and Fraud Risk deep dive pages. Demonstrate the What If fraud score threshold slider live if presenting in Power BI, or reference the wireframe if presenting statically.

**Slide 9, Recommendations and Action Plan.** Four actions: mandatory secondary review above the fraud threshold, quarterly agent loss ratio review, targeted retention campaign for high value low risk customers, and fixing the upstream data reconciliation issue.

**Slide 10, Impact.** Projected 3 to 5 point loss ratio improvement without repricing the healthy 80 percent of the book.

**Slide 11, Technical Skills Demonstrated.** CTEs, window functions, stored procedures, views, temp tables, cohort analysis, funnel analysis, star schema modeling, DAX, RLS, forecasting, bookmarks, drill through.

**Slide 12, Closing.** Every number in this deck traces back to a reusable SQL query in the repository, not a one time spreadsheet calculation.
