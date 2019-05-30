CREATE TABLE Books (
               id INTEGER PRIMARY KEY,
               category TEXT,
               price FLOAT,
               promoted BOOLEAN DEFAULT True
);

INSERT INTO Books (id, category, price) VALUES(1, 'Dictionary', 100);
INSERT INTO Books (id, category, price) VALUES(2, 'Dictionary', 150);
INSERT INTO Books (id, category, price) VALUES(3, 'Science', 120);
INSERT INTO Books (id, category, price) VALUES(4, 'Science', 190);
INSERT INTO Books (id, category, price) VALUES(5, 'Science', 320);

SELECT * FROM Books;

CREATE VIEW PromotionSummary AS
               SELECT category, MIN(price) AS minprice, MAX(price) AS maxprice
               FROM Books
               WHERE promoted
               GROUP BY category;

SELECT * FROM PromotionSummary;

CREATE OR REPLACE FUNCTION updateStatusBooks() RETURNS TRIGGER AS $$
BEGIN
               UPDATE Books SET promoted = False WHERE category = OLD.category;
               RETURN NULL;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER updateStatusBooksTrigger
               INSTEAD OF DELETE ON PromotionSummary
               FOR EACH STATEMENT
               EXECUTE PROCEDURE updateStatusBooks();

DELETE FROM PromotionSummary
               WHERE category = 'Dictionary';

SELECT * FROM Books;

SELECT * FROM PromotionSummary;