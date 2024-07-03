/*
Table: customers
Description: This table contains information about the customers.
Columns:
  - customerNumber: Unique identifier for each customer (Primary Key).
  - customerName: Name of the customer.
  - contactLastName: Last name of the customer contact.
  - contactFirstName: First name of the customer contact.
  - phone: Phone number of the customer.
  - addressLine1: Primary address line.
  - addressLine2: Secondary address line (optional).
  - city: City of the customer's address.
  - state: State of the customer's address (optional).
  - postalCode: Postal code of the customer's address (optional).
  - country: Country of the customer's address.
  - salesRepEmployeeNumber: Employee number of the sales representative (Foreign Key referencing employees(employeeNumber)).
  - creditLimit: Credit limit of the customer.
*/

/*
Table: employees
Description: This table contains information about the employees.
Columns:
  - employeeNumber: Unique identifier for each employee (Primary Key).
  - lastName: Last name of the employee.
  - firstName: First name of the employee.
  - extension: Extension number for the employee.
  - email: Email address of the employee.
  - officeCode: Code of the office where the employee works (Foreign Key referencing offices(officeCode)).
  - reportsTo: Employee number of the manager (optional, Foreign Key referencing employees(employeeNumber)).
  - jobTitle: Job title of the employee.
*/

/*
Table: offices
Description: This table contains information about the offices.
Columns:
  - officeCode: Unique code for each office (Primary Key).
  - city: City where the office is located.
  - phone: Phone number of the office.
  - addressLine1: Primary address line.
  - addressLine2: Secondary address line (optional).
  - state: State where the office is located (optional).
  - country: Country where the office is located.
  - postalCode: Postal code of the office.
  - territory: Territory of the office.
*/

/*
Table: orderdetails
Description: This table contains details of the orders.
Columns:
  - orderNumber: Unique identifier for each order (Primary Key, Foreign Key referencing orders(orderNumber)).
  - productCode: Code of the product ordered (Primary Key, Foreign Key referencing products(productCode)).
  - quantityOrdered: Quantity of the product ordered.
  - priceEach: Price of each unit of the product.
  - orderLineNumber: Line number of the order.
*/

/*
Table: orders
Description: This table contains information about the orders.
Columns:
  - orderNumber: Unique identifier for each order (Primary Key).
  - orderDate: Date when the order was placed.
  - requiredDate: Date by which the order is required.
  - shippedDate: Date when the order was shipped (optional).
  - status: Status of the order.
  - comments: Additional comments about the order (optional).
  - customerNumber: ID of the customer who placed the order (Foreign Key referencing customers(customerNumber)).
*/

/*
Table: payments
Description: This table contains information about payments made by customers.
Columns:
  - customerNumber: Unique identifier for the customer (Primary Key, Foreign Key referencing customers(customerNumber)).
  - checkNumber: Check number used for the payment (Primary Key).
  - paymentDate: Date when the payment was made.
  - amount: Amount paid.
*/

/*
Table: productlines
Description: This table contains information about product lines.
Columns:
  - productLine: Unique identifier for each product line (Primary Key).
  - textDescription: Text description of the product line (optional).
  - htmlDescription: HTML description of the product line (optional).
  - image: Image of the product line (optional).
*/

/*
Table: products
Description: This table contains information about the products.
Columns:
  - productCode: Unique code for each product (Primary Key).
  - productName: Name of the product.
  - productLine: Product line to which the product belongs (Foreign Key referencing productlines(productLine)).
  - productScale: Scale of the product.
  - productVendor: Vendor of the product.
  - productDescription: Description of the product.
  - quantityInStock: Quantity of the product in stock.
  - buyPrice: Buying price of the product.
  - MSRP: Manufacturer's suggested retail price.
*/

/*
Brief description of the database schema and relationships:
- The `customers` table stores information about customers and links to the `employees` table through `salesRepEmployeeNumber`.
- The `employees` table stores employee details and links to the `offices` table through `officeCode`.
- The `offices` table stores information about the office locations.
- The `orders` table stores order information and links to the `customers` table through `customerNumber`.
- The `orderdetails` table stores details of each order and links to the `orders` table through `orderNumber` and the `products` table through `productCode`.
- The `payments` table stores payment information and links to the `customers` table through `customerNumber`.
- The `productlines` table stores information about product lines.
- The `products` table stores product details and links to the `productlines` table through `productLine`.
*/

-- Query to retrieve table names, count of attributes, and count of rows for each table
WITH table_info AS (
    SELECT 'customers' AS table_name, COUNT(*) AS number_of_attributes
    FROM pragma_table_info('customers')
    UNION ALL
    SELECT 'employees', COUNT(*)
    FROM pragma_table_info('employees')
    UNION ALL
    SELECT 'offices', COUNT(*)
    FROM pragma_table_info('offices')
    UNION ALL
    SELECT 'orderdetails', COUNT(*)
    FROM pragma_table_info('orderdetails')
    UNION ALL
    SELECT 'orders', COUNT(*)
    FROM pragma_table_info('orders')
    UNION ALL
    SELECT 'payments', COUNT(*)
    FROM pragma_table_info('payments')
    UNION ALL
    SELECT 'productlines', COUNT(*)
    FROM pragma_table_info('productlines')
    UNION ALL
    SELECT 'products', COUNT(*)
    FROM pragma_table_info('products')
),
row_counts AS (
    SELECT 'customers' AS table_name, COUNT(*) AS number_of_rows
    FROM customers
    UNION ALL
    SELECT 'employees', COUNT(*)
    FROM employees
    UNION ALL
    SELECT 'offices', COUNT(*)
    FROM offices
    UNION ALL
    SELECT 'orderdetails', COUNT(*)
    FROM orderdetails
    UNION ALL
    SELECT 'orders', COUNT(*)
    FROM orders
    UNION ALL
    SELECT 'payments', COUNT(*)
    FROM payments
    UNION ALL
    SELECT 'productlines', COUNT(*)
    FROM productlines
    UNION ALL
    SELECT 'products', COUNT(*)
    FROM products
)
SELECT table_info.table_name, table_info.number_of_attributes, row_counts.number_of_rows
FROM table_info
JOIN row_counts ON table_info.table_name = row_counts.table_name;

-- Question:
-- Compute the low stock for each product and the product performance for each product. 
-- Then, combine these results to display the priority products for restocking using a Common Table Expression (CTE) 
-- and the IN operator. The goal is to identify products that are both low in stock and high in performance (i.e., 
-- have high sales) and need to be restocked first.

-- Solution:
-- Step 1: Use a CTE to calculate the low stock for each product. This involves computing the average quantity ordered 
-- for each product using a correlated subquery, and rounding the result to the nearest hundredth.
-- Step 2: Use another CTE to calculate the product performance for each product. This involves summing the quantities 
-- ordered for each product, grouping the rows by productCode, and selecting the top ten products by product performance.
-- Step 3: Combine these CTEs to identify priority products for restocking. This involves selecting products from the 
-- low stock CTE that are also in the top performance CTE using the IN operator.

-- CTE to compute the low stock for each product
WITH low_stock AS (
    SELECT p.productCode,
           ROUND((SELECT AVG(od.quantityOrdered)
                  FROM orderdetails od
                  WHERE od.productCode = p.productCode), 2) AS low_stock
    FROM products p
),
-- CTE to compute the top ten products by product performance
top_performance AS (
    SELECT productCode,
           SUM(quantityOrdered) AS product_performance
    FROM orderdetails
    GROUP BY productCode
    ORDER BY product_performance DESC
    LIMIT 10
)
-- Final query to select priority products for restocking
SELECT low_stock.productCode, low_stock.low_stock
FROM low_stock
WHERE low_stock.productCode IN (SELECT productCode FROM top_performance)
ORDER BY low_stock.low_stock ASC;

-- Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
-- Write a query to join the products, orders, and orderdetails tables to have customers and products information in the same place.
-- Select customerNumber and compute, for each customer, the profit, which is the sum of quantityOrdered multiplied by priceEach minus buyPrice: 
-- SUM(quantityOrdered * (priceEach - buyPrice)).

-- CTE to compute profit for each customer
WITH customer_profits AS (
    SELECT o.customerNumber,
           SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    JOIN products p ON od.productCode = p.productCode
    GROUP BY o.customerNumber
)
-- Query to find the top five VIP customers
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, cp.profit
FROM customer_profits cp
JOIN customers c ON cp.customerNumber = c.customerNumber
ORDER BY cp.profit DESC
LIMIT 5;

-- CTE to compute profit for each customer
WITH customer_profits AS (
    SELECT o.customerNumber,
           SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    JOIN products p ON od.productCode = p.productCode
    GROUP BY o.customerNumber
)
-- Query to find the top five least-engaged customers
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, cp.profit
FROM customer_profits cp
JOIN customers c ON cp.customerNumber = c.customerNumber
ORDER BY cp.profit ASC
LIMIT 5;

-- CTE to compute profit for each customer
WITH customer_profits AS (
    SELECT o.customerNumber,
           SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    JOIN products p ON od.productCode = p.productCode
    GROUP BY o.customerNumber
)
-- Query to compute the average of customer profits
SELECT AVG(cp.profit) AS average_profit
FROM customer_profits cp;
/*
To address the questions on matching marketing and communication strategies to customer behavior, determining the budget for acquiring new customers, and identifying which products to order more of or less of, we utilized a series of SQL queries to analyze the database. 
We first identified the top five VIP customers and the top five least-engaged customers by calculating the profit generated by each customer. 
This was achieved by joining the `products`, `orders`, and `orderdetails` tables and then grouping by `customerNumber`. 
Understanding which customers contribute the most and the least to our revenue allows us to tailor our marketing strategies to better engage with high-value customers and re-engage or optimize spending on less-engaged customers.

To determine how much we can spend on acquiring new customers, we computed the average profit per customer using a Common Table Expression (CTE). This provided a benchmark for the average revenue generated by a customer, essential for calculating an appropriate customer acquisition cost. 
Additionally, by analyzing product performance and stock levels, we identified priority products for restocking using a correlated subquery to compute low stock for each product and identified top-performing products by their sales. 
This analysis helps determine which products should be ordered more due to high demand and low stock levels, ensuring we meet customer needs effectively. Products with lower performance and adequate stock might be ordered less, optimizing inventory management and reducing carrying costs. 
This data-driven approach provides valuable insights into customer behavior, marketing strategies, budget optimization, and inventory management.
*/
