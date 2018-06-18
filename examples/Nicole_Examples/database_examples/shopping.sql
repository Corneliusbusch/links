CREATE TABLE Products (
    pid int NOT NULL,
    product character varying(255),
    price decimal(10,2),
    PRIMARY KEY(pid)
);

INSERT INTO Products(pid, product, price) VALUES 
    (1, 'Strawberries', 1.49),
    (2, 'Blueberries', 2),
    (3, 'Banana', 0.22),
    (4, 'Water', 0.44),
    (5, 'Lettuce', 0.5),
    (6, 'Chicken Breast Fillet', 3.69),
    (7, 'Ballon', 1.0),
    (8, 'Screw', 0.2),
    (9, 'Camera', 449.99),
    (10, 'Shoe Lace', 2.99),
    (11, 'Blanket', 29.99),
    (12, 'Apple', 0.5),
    (13, 'Chocolate Cake', 2.79),
    (14, 'Rye Bread', 1.89),
    (15, 'Full Fat Soft Cheese', 2.00),
    (16, 'Light Soft Cheese', 2.10),
    (17, 'Potted Rose Plant', 3.99),
    (18, 'Basil', 0.7),
    (19, 'Red Peppers', 0.6);


CREATE TABLE Cart (
    pid int PRIMARY KEY,
    qty int NOT NULL,
    FOREIGN KEY(pid) REFERENCES Products(pid)
);

INSERT INTO Cart VALUES 
    (0001, 3),
    (0005, 1), 
    (0011, 1),
    (0014, 3),
    (0018, 1),
    (0002, 2);

