WITH union_ads AS (
    SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_campaign,
        utm_medium,
        SUM(daily_spent) AS spent
    FROM vk_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_campaign,
        utm_medium
    UNION
    SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_campaign,
        utm_medium,
        SUM(daily_spent) AS spent
    FROM ya_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_campaign,
        utm_medium
),

tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY
        visitor_id
),

last_paid_attribution AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM
        sessions AS s
    INNER JOIN
        tab AS t
        ON s.visitor_id = t.visitor_id AND s.visit_date = t.last_visit
    LEFT JOIN
        leads AS l
        ON l.visitor_id = s.visitor_id AND l.created_at >= t.last_visit
),

aggregate_last_paid AS (
    SELECT
        lpa.utm_source,
        lpa.utm_medium,
        lpa.utm_campaign,
        DATE(lpa.visit_date) AS visit_date,
        COUNT(DISTINCT lpa.visitor_id) AS visitors_count,
        COUNT(lpa.lead_id) AS leads_count,
        COUNT(lpa.amount) FILTER (
            WHERE lpa.closing_reason = 'Успешно реализованно'
            OR lpa.status_id = 142
        ) AS purchases_count,
        SUM(lpa.amount) AS revenue
    FROM
        last_paid_attribution AS lpa
    GROUP BY
        visit_date,
        lpa.utm_source,
        lpa.utm_medium,
        lpa.utm_campaign
)

SELECT
    alp.visit_date,
    alp.visitors_count,
    alp.utm_source,
    alp.utm_medium,
    alp.utm_campaign,
    ua.spent AS total_cost,
    alp.leads_count,
    alp.purchases_count,
    alp.revenue
FROM
    aggregate_last_paid AS alp
LEFT JOIN
    union_ads AS ua ON
    alp.utm_source = ua.utm_source
    AND alp.utm_campaign = ua.utm_campaign
    AND alp.utm_medium = ua.utm_medium
    AND alp.visit_date = ua.campaign_date
ORDER BY
    alp.revenue DESC NULLS LAST,
    alp.visit_date ASC,
    alp.visitors_count DESC,
    alp.utm_source ASC,
    alp.utm_medium ASC,
    alp.utm_campaign ASC;
