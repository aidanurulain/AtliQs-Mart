SELECT * 
FROM dim_campaigns;

SELECT *
FROM dim_products;

SELECT *
FROM dim_stores;

SELECT *
FROM fact_events;

-- 1) product b.price > 500 with BOGOF promo (high value product which heavily discounted)
SELECT fe.product_code,
	   dp.product_name,
	   fe.base_price
FROM fact_events fe
JOIN dim_products dp ON fe.product_code = dp.product_code
WHERE fe.promo_type = 'BOGOF' AND fe.base_price > 500;

-- 2) overview no. of store in each city
SELECT city,COUNT(*) as count_store_id
FROM dim_stores 
GROUP BY city
ORDER BY count_store_id DESC;    

-- 3) Total revenue by each campaign before & after promo
DROP TABLE revenue;
CREATE TEMPORARY TABLE revenue
SELECT fe.campaign_id,
		dc.campaign_name,
		quantity_sold_before_promo,
		quantity_sold_after_promo,
		promo_type,
        fe.base_price,
        fe.base_price*quantity_sold_before_promo as rev_bp,
  ROUND(CASE 
		WHEN promo_type = '50% OFF' THEN base_price*0.50*quantity_sold_after_promo
		WHEN promo_type = '25% OFF' THEN base_price*0.75*quantity_sold_after_promo
		WHEN promo_type = '33% OFF' THEN base_price*0.67*quantity_sold_after_promo
		WHEN promo_type = '500 Cashback' THEN (base_price-500)*quantity_sold_after_promo
		WHEN promo_type = 'BOGOF' THEN base_price*0.50*quantity_sold_after_promo*2
	END,2) AS rev_ap
FROM fact_events fe
LEFT JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id;

SELECT * FROM revenue;

SELECT campaign_name,ROUND((SUM(rev_bp)/1000000),2) as totalrevenue_beforepromo,ROUND((SUM(rev_ap)/1000000),2) as totalrevenue_afterpromo
FROM revenue
GROUP BY campaign_name;

-- 4) Calculation Increamental Sold Quantity(ISU%) for each product category during diwali campagin
     -- ranked based on ISU%
     -- include 3 field; category, ISU%, rank order
SELECT dp.category,
       ((SUM(quantity_sold_after_promo)-SUM(quantity_sold_before_promo))/SUM(quantity_sold_before_promo)) AS ISU_value,
       ((SUM(quantity_sold_after_promo)-SUM(quantity_sold_before_promo))/SUM(quantity_sold_before_promo))*100 AS ISU_percent,
       DENSE_RANK() OVER (ORDER BY (SUM(quantity_sold_after_promo-quantity_sold_before_promo)/SUM(quantity_sold_before_promo)) DESC) AS ISU_rank
FROM fact_events fe
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
JOIN dim_products dp ON fe.product_code = dp.product_code
WHERE campaign_name = 'Diwali'
GROUP BY dp.category
ORDER BY ISU_percent DESC;

-- 5) Top 5 product ranked by Incremental Revenue (IR%) for all campaign
     -- report include product name, category & IR%
DROP TABLE IR_value;
CREATE TEMPORARY TABLE IR_value
SELECT  fe.campaign_id,
		fe.promo_type,
		base_price,
        quantity_sold_before_promo,
        quantity_sold_after_promo,
        dc.campaign_name,
        dp.category,
        dp.product_name,
        fe.base_price*quantity_sold_before_promo as rev_bp,
  ROUND(CASE 
		WHEN promo_type = '50% OFF' THEN base_price*0.50*quantity_sold_after_promo
		WHEN promo_type = '25% OFF' THEN base_price*0.75*quantity_sold_after_promo
		WHEN promo_type = '33% OFF' THEN base_price*0.67*quantity_sold_after_promo
		WHEN promo_type = '500 Cashback' THEN (base_price-500)*quantity_sold_after_promo
		WHEN promo_type = 'BOGOF' THEN base_price*0.50*quantity_sold_after_promo*2
	END,0) AS rev_ap
FROM fact_events fe
LEFT JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
LEFT JOIN dim_products dp ON fe.product_code = dp.product_code;

SELECT * FROM IR_value;


SELECT category,product_name,ROUND((((SUM(rev_ap) - SUM(rev_bp))/SUM(rev_bp))*100),2) AS IR_v
FROM IR_value
GROUP BY category,product_name
ORDER BY IR_v DESC
LIMIT 5;

SELECT ((SUM(quantity_sold_after_promo)-SUM(quantity_sold_before_promo))/SUM(quantity_sold_before_promo))*100
FROM fact_events;

SELECT *
FROM fact_events;

SELECT *,
       ((quantity_sold_after_promo)-(quantity_sold_before_promo))/(quantity_sold_before_promo) AS ISU_value
FROM fact_events fe
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
JOIN dim_products dp ON fe.product_code = dp.product_code;




