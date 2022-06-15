USE sakila;


-- The store customer base (country)
SELECT 
	t2.country,
    COUNT(*) AS n_active_customers
FROM customer AS t1
LEFT JOIN
(	
    SELECT
		address_id,
		address,
		district,
		t3.city_id,
		t4.city,
		t4.country_id,
        t4.country
	FROM address AS t3
	LEFT JOIN
	(
		SELECT 
			city_id, 
			city, 
			t5.country_id,
			t6.country
		FROM city AS t5
		LEFT JOIN country AS t6
		ON t5.country_id = t6.country_id
	) AS t4
	ON t3.city_id = t4.city_id
) AS t2
ON t1.address_id = t2.address_id
WHERE active = 1
GROUP BY 1
ORDER BY 2 DESC;


-- Customers with the most # of rent
SELECT
	temp1.customer_id,
    temp1.customer_name,
    temp1.n_rents
FROM
(
	SELECT
		t0.customer_id,
		t1.customer_name,
		COUNT(*) AS n_rents
	FROM rental AS t0
	LEFT JOIN
    (
		SELECT
			t4.customer_id,
			CONCAT(t4.first_name, ' ', t4.last_name) AS customer_name,
			t4.address_id,
            t2.country,
            t2.city
        FROM customer AS t4
        LEFT JOIN
        (
			SELECT 
				t5.address_id,
                t3.country,
                t3.city
            FROM address AS t5
            LEFT JOIN
            (
				SELECT
					t7.country,
                    t6.city_id,
                    t6.city
                FROM city AS t6
                LEFT JOIN country AS t7
                ON t6.country_id = t7.country_id
            ) AS t3
            ON t3.city_id = t5.city_id
        ) AS t2
        ON t2.address_id = t4.address_id
    ) AS t1 
	ON t0.customer_id = t1.customer_id
    GROUP BY 1
	ORDER BY 3 DESC
) AS temp1
INNER JOIN
(
	SELECT COUNT(*) AS n_rents
	FROM rental AS t8
	LEFT JOIN customer AS t9
	ON t8.customer_id = t9.customer_id
	GROUP BY t8.customer_id
	ORDER BY 1 DESC
	LIMIT 3
) AS temp2
ON temp1.n_rents = temp2.n_rents;


-- Countries with the most inactive customers
SELECT
	a.country,
    IFNULL(a.inactive_customers, 0) AS n_inactive_customer,
    IFNULL(a.inactive_customers/(a.inactive_customers + b.active_customers)*100, 0) AS n_inactive_customer_percentage
FROM
(
	SELECT 
		t2.country,
		COUNT(*) AS inactive_customers
	FROM customer AS t1
	LEFT JOIN
	(	
		SELECT
			address_id,
			address,
			district,
			t3.city_id,
			t4.city,
			t4.country_id,
			t4.country
		FROM address AS t3
		LEFT JOIN
		(
			SELECT 
				city_id, 
				city, 
				t5.country_id,
				t6.country
			FROM city AS t5
			LEFT JOIN country AS t6
			ON t5.country_id = t6.country_id
		) AS t4
		ON t3.city_id = t4.city_id
	) AS t2
	ON t1.address_id = t2.address_id
	WHERE active = 0
	GROUP BY 1
) AS a
LEFT JOIN
(
	SELECT 
	t8.country,
    COUNT(*) AS active_customers
FROM customer AS t7
LEFT JOIN
(	
    SELECT
		address_id,
		address,
		district,
		t9.city_id,
		t10.city,
		t10.country_id,
        t10.country
	FROM address AS t9
	LEFT JOIN
	(
		SELECT 
			city_id, 
			city, 
			t11.country_id,
			t12.country
		FROM city AS t11
		LEFT JOIN country AS t12
		ON t11.country_id = t12.country_id
	) AS t10
	ON t9.city_id = t10.city_id
) AS t8
ON t7.address_id = t8.address_id
WHERE active = 1
GROUP BY 1
) AS b
ON a.country = b.country;


-- # of movies for each actor
SELECT
	t1.actor_id,
    CONCAT(t1.first_name, ' ', t1.last_name) AS actor_name,
    COUNT(*) AS n_movies
FROM actor AS t1
RIGHT JOIN film_actor AS t2
ON t1.actor_id = t2.actor_id
GROUP BY 1
ORDER BY 3 DESC;


-- Most frequent rented film info
SELECT *
FROM
(
	SELECT
		t1.film_id,
        t2.title,
        t2.description,
        t2.length,
        t2.rating,
		COUNT(*) AS n_rents,
        t2.special_features
	FROM
	(
		SELECT
			t4.rental_id,
			t3.film_id
		FROM inventory AS t3
		LEFT JOIN rental AS t4
		ON t3.inventory_id = t4.inventory_id
	) AS t1
	LEFT JOIN 
    (
		SELECT
			temp2.*,
            temp1.length,
            temp1.rating,
            temp1.special_features
        FROM film AS temp1
        INNER JOIN film_text AS temp2
        ON temp1.film_id = temp2.film_id
    ) AS t2
	ON t1.film_id = t2.film_id
	GROUP BY 1
	ORDER BY 2 DESC
) AS p
WHERE p.n_rents =
(
	SELECT
		COUNT(*) AS n_rents
	FROM
	(
		SELECT
			t8.rental_id,
			t7.film_id
		FROM inventory AS t7
		LEFT JOIN rental AS t8
		ON t7.inventory_id = t8.inventory_id
	) AS t5
	LEFT JOIN film AS t6
	ON t5.film_id = t6.film_id
	GROUP BY t5.film_id
	ORDER BY 1 DESC
    LIMIT 1
);


-- Most frequent rented genre
SELECT
	b.category_id,
    a.name,
    b.n_rents
FROM category AS a
RIGHT JOIN
(	
    SELECT
		t1.category_id,
		COUNT(t2.film_id) AS n_rents
	FROM film_category AS t1
	LEFT JOIN
	(
		SELECT
			t4.rental_id,
			t3.language_id,
			t4.film_id
		FROM film AS t3
		LEFT JOIN
		(
			SELECT
				t6.rental_id,
				t5.film_id
			FROM inventory AS t5
			LEFT JOIN rental AS t6
			ON t5.inventory_id = t6.inventory_id
		) AS t4
		ON t3.film_id = t4.film_id
	) AS t2
	ON t1.film_id = t2.film_id
	GROUP BY 1
	ORDER BY 2 DESC
) AS b
ON a.category_id = b.category_id;


-- Films that are never have been rented
SELECT
	temp.film_id,
    temp.title,
    temp.description,
    temp.length,
    temp.rating,
    CASE
		WHEN COALESCE(rented, 0) > 0 THEN 1
		ELSE 0
	END AS is_rented
FROM
(
	SELECT
		film_id,
        title,
        description,
        length,
		rating,
        CASE
			WHEN COALESCE(rental_id, 0) > 0 THEN 1
			ELSE 0
		END AS rented
	FROM
	(	
		SELECT
			t1.film_id,
			t2.rental_id,
            t1.title,
            t1.description,
            t1.length,
            t1.rating
		FROM 
		(
            SELECT
				temp3.*,
				temp2.length,
				temp2.rating,
				temp2.special_features
			FROM film AS temp2
			INNER JOIN film_text AS temp3
			ON temp2.film_id = temp3.film_id
		) AS t1
        LEFT JOIN
		(
			SELECT
				t4.rental_id,
				t3.film_id
			FROM inventory AS t3
			LEFT JOIN rental AS t4
			ON t3.inventory_id = t4.inventory_id
		) AS t2
		ON t1.film_id = t2.film_id
	) AS temp1
) AS temp
GROUP BY 1
HAVING is_rented = 0;


-- Unrented film percentage for each rating
SELECT
	d.rating,
    c.n_unrented/d.n_rented*100 AS unrented_percentage
FROM
(	
    SELECT 
		DISTINCT a.rating,
		COUNT(a.film_id) AS n_unrented
	FROM
	(
		SELECT
			temp.film_id,
			temp.rating,
			CASE
				WHEN COALESCE(rented, 0) > 0 THEN 1
				ELSE 0
			END AS is_rented
		FROM
		(
			SELECT
				film_id,
				rating,
				CASE
					WHEN COALESCE(rental_id, 0) > 0 THEN 1
					ELSE 0
				END AS rented
			FROM
			(	
				SELECT
					t1.film_id,
					t2.rental_id,
					t1.rating
				FROM film AS t1
				LEFT JOIN
				(
					SELECT
						t4.rental_id,
						t3.film_id
					FROM inventory AS t3
					LEFT JOIN rental AS t4
					ON t3.inventory_id = t4.inventory_id
				) AS t2
				ON t1.film_id = t2.film_id
			) AS temp1
		) AS temp
		GROUP BY 1
		HAVING is_rented = 0
	) AS a
	GROUP BY a.rating
    ORDER BY a.rating
) AS c
INNER JOIN
(	
    SELECT 
		DISTINCT b.rating,
		COUNT(b.film_id) AS n_rented
	FROM
	(
		SELECT
			temp.film_id,
			temp.rating,
			CASE
				WHEN COALESCE(rented, 0) > 0 THEN 1
				ELSE 0
			END AS is_rented
		FROM
		(
			SELECT
				film_id,
				rating,
				CASE
					WHEN COALESCE(rental_id, 0) > 0 THEN 1
					ELSE 0
				END AS rented
			FROM
			(	
				SELECT
					t1.film_id,
					t2.rental_id,
					t1.rating
				FROM film AS t1
				LEFT JOIN
				(
					SELECT
						t4.rental_id,
						t3.film_id
					FROM inventory AS t3
					LEFT JOIN rental AS t4
					ON t3.inventory_id = t4.inventory_id
				) AS t2
				ON t1.film_id = t2.film_id
			) AS temp1
		) AS temp
		GROUP BY 1
	) AS b
	GROUP BY b.rating
    ORDER BY b.rating
) AS d
ON c.rating = d.rating