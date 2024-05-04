WITH union_ads AS (
    SELECT utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads va
    UNION ALL
    SELECT utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads ya
),
last_paid_attribution AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
        FROM sessions
        WHERE medium <> 'organic'
        GROUP BY visitor_id
),
result_table AS (
    SELECT
        visit_date, 
        utm_source, 
        utm_medium, 
        utm_campaign,
        COUNT(l.visitor_id) AS visitors_count,
        SUM(daily_spent) AS total_cost,
        COUNT(lead_id) AS leads_count,
        COUNT(CASE WHEN closing_reason = 'Успешно реализовано' OR status_id = 142 THEN 1 END) AS purchases_count,
        SUM(CASE WHEN status_id = 142 THEN amount END) AS revenue
    FROM sessions s 
    INNER JOIN leads l ON s.visitor_id = l.visitor_id
    INNER JOIN union_ads ua ON s.campaign = ua.utm_campaign AND s.medium = ua.utm_medium AND s.source = ua.utm_source
    INNER JOIN last_paid_attribution lpa ON lpa.visitor_id = s.visitor_id AND lpa.last_visit = s.visit_date
    WHERE utm_medium <> 'organic'
    GROUP BY s.visit_date, utm_source, utm_medium, utm_campaign
)
SELECT *
FROM result_table
ORDER BY revenue DESC NULLS LAST, visit_date, visitors_count DESC, utm_source, utm_medium, utm_campaign;
