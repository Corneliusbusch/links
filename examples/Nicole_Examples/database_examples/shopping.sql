CREATE TABLE Products (
    pid int NOT NULL,
    product character varying(255),
    price decimal(10,2),
    PRIMARY KEY(pid)
);

INSERT INTO Products(pid, product, price) VALUES 
    (0001, 'Strawberries', 1.49),
    (0002, 'Blueberries', 2),
    (0003, 'Banana', 0.22),
    (0004, 'Water', 0.44),
    (0005, 'Lettuce', 0.5),
    (0006, 'Chicken Breast Fillet', 3.69),
    (0007, 'Ballon', 1.0),
    (0008, 'Screw', 0.2),
    (0009, 'Camera', 449.99),
    (0010, 'Shoe Lace', 2.99),
    (0011, 'Blanket', 29.99),
    (0012, 'Apple', 0.5),
    (0013, 'Chocolate Cake', 2.79),
    (0014, 'Rye Bread', 1.89),
    (0015, 'Full Fat Soft Cheese', 2.00),
    (0016, 'Light Soft Cheese', 2.10),
    (0017, 'Potted Rose Plant', 3.99),
    (0018, 'Basil', 0.7),
    (0019, 'Red Peppers', 0.6);


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

