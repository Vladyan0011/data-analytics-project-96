-- last_paid_click attribution
WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY visitor_id
),

diff_tab AS (
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
        l.status_id,
        l.created_at - s.visit_date AS diff
    FROM tab AS t
    INNER JOIN sessions AS s
        ON t.visitor_id = s.visitor_id
        AND t.last_visit = s.visit_date
    LEFT JOIN leads AS l
        ON s.visitor_id =l.visitor_id
        AND t.last_visit <= l.created_at
    WHERE closing_reason  = 'Успешная продажа' OR status_id = 142
    ORDER BY
        l.amount DESC NULLS LAST,
        visit_date ASC,
        utm_source ASC,
        utm_medium ASC,
        utm_campaign ASC
)
SELECT
    PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY diff) AS p_90
FROM diff_tab

-- count organic and traffic visits
WITH tab AS (
    SELECT
        visitor_id,
        visit_date,
        CASE
        	WHEN medium = 'organic' THEN medium
    	    ELSE 'ads'
        END AS source
    FROM sessions
),
ads AS (
    SELECT
        DATE(visit_date) AS visit_date,
        COUNT(visitor_id) AS ads_visitors
    FROM tab
    WHERE SOURCE = 'ads'
    GROUP BY DATE(visit_date)
    ORDER BY visit_date ASC
),
organic AS (
    SELECT
        DATE(visit_date) AS visit_date,
        COUNT(visitor_id) AS organic_visitors
    FROM tab
    WHERE SOURCE = 'organic'
    GROUP BY DATE(visit_date)
    ORDER BY visit_date ASC
)
SELECT
    ads.visit_date,
    ads.ads_visitors,
    organic.organic_visitors
FROM ads
LEFT JOIN organic ON ads.visit_date = organic.visit_date
