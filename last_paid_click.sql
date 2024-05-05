WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY visitor_id
)

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
FROM tab AS t
INNER JOIN 
    sessions s ON
        t.visitor_id = s.visitor_id AND t.last_visit = s.visit_date
LEFT JOIN 
    leads AS l ON
        s.visitor_id =l.visitor_id AND t.last_visit <= l.created_at
ORDER BY
    l.amount DESC NULLS LAST,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign;
