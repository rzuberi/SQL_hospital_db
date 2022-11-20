-- Exercise 1
DROP TABLE IF EXISTS medical_record;
CREATE TABLE medical_record (
rec_no     SMALLINT UNSIGNED AUTO_INCREMENT,
patient    CHAR(9),
doctor     CHAR(9),
entered_on DATETIME  NOT NULL DEFAULT NOW(),
diagnosis  MEDIUMTEXT NOT NULL,
treatment  VARCHAR(1000),
PRIMARY KEY   (rec_no, patient),
CONSTRAINT    FK_patient
	FOREIGN KEY   (patient)
	REFERENCES    patient(ni_number)
	ON UPDATE RESTRICT
	ON DELETE CASCADE,
CONSTRAINT FK_doctor
	FOREIGN KEY (doctor)
	REFERENCES doctor(ni_number)
	ON UPDATE RESTRICT
	ON DELETE SET NULL
)ENGINE=MyISAM; -- this permits the rec_no increment to be specific to the patient, not to the entire table


-- Exercise 2
ALTER TABLE medical_record
	ADD duration TIME;


-- Exercise 3
UPDATE doctor
	SET salary =
		CASE WHEN expertise LIKE '%ear%' 
			THEN salary - (salary * 0.1)
		ELSE salary
		END;


-- Exercise 4
SELECT fname, lname, YEAR(date_of_birth) AS born
FROM patient
WHERE city LIKE '%right%'
ORDER BY lname, fname;


-- Exercise 5
SELECT ni_number, fname, lname, ROUND((weight/( POWER( (height/100) ,2) ) ),3) AS BMI
FROM patient
WHERE TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 30; -- measures current difference between their dob and the current date and checks if less than 30


-- Exercise 6
SELECT COUNT(*) AS number FROM doctor;


-- Exercise 7
SELECT doctor.ni_number, doctor.lname, COUNT(carries_out.doctor) AS operations
FROM doctor LEFT JOIN carries_out
ON doctor.ni_number = carries_out.doctor
WHERE YEAR(carries_out.start_date_time) = YEAR(NOW())
GROUP BY doctor.ni_number
ORDER BY operations desc;


-- Exercise 8
SELECT DISTINCT mentoree.ni_number, UPPER(LEFT(mentoree.fname, 1)) as init, mentoree.lname
FROM doctor mentored, doctor mentoree
WHERE mentored.mentored_by = mentoree.ni_number
	AND mentoree.mentored_by IS NULL;


-- Exercise 9
SELECT a.theatre_no as theatre, DATE_FORMAT(a.start_date_time,'%Y-%m-%d %H:%i') as start_time_1, DATE_FORMAT(b.start_date_time,'%H:%i') as start_time_2
FROM operation a, operation b
WHERE a.theatre_no = b.theatre_no
	AND a.start_date_time < b.start_date_time -- a started before b
	AND ADDTIME(a.start_date_time, a.duration) > b.start_date_time; -- and the end time of a is after b


-- Exercise 10
SELECT a.theatre_no, DAY(a.start_date) as dom, MONTHNAME(a.start_date) as month, YEAR(a.start_date) as year, a.num_of_ops as num_ops 
FROM (SELECT theatre_no, DATE(start_date_time) as start_date, COUNT(*) as num_of_ops
		FROM operation
		GROUP BY theatre_no, start_date) a
LEFT JOIN (SELECT theatre_no, DATE(start_date_time) as start_date, COUNT(*) as num_of_ops
		FROM operation
		GROUP BY theatre_no, start_date) b
ON a.theatre_no = b.theatre_no AND a.num_of_ops < b.num_of_ops -- each row is matched with the rows from the same group that have a bigger value
WHERE b.num_of_ops is NULL -- the day(s) with the most operations from 'a' will be matched with rows of nulls
ORDER BY theatre_no, a.start_date; -- already the normal order, but just in case
	

-- Exercise 11
DROP FUNCTION IF EXISTS usage_theatre;
DELIMITER $$

CREATE FUNCTION usage_theatre(
		input_theatre_num INT,
		given_year INT(4) unsigned
	
)
RETURNS VARCHAR(50) -- to save space, assume it's unrealistic for the result string to exceed 50 chars
BEGIN
	DECLARE usage_time VARCHAR(50);

	IF given_year > YEAR(NOW()) THEN
			SET usage_time = 'The year is in the future';
	ELSEIF NOT EXISTS(SELECT * FROM operation WHERE theatre_no = input_theatre_num ) THEN
			SET usage_time = CONCAT('There is no operating theatre ', input_theatre_num);
	ELSE	SET @total_seconds = (SELECT SUM(TIME_TO_SEC(duration)) FROM operation WHERE theatre_no = input_theatre_num AND YEAR(start_date_time) = given_year);
			SET usage_time = CONCAT(FORMAT(FLOOR(@total_seconds / 86400),0), 'days ', TIME_FORMAT(SEC_TO_TIME(@total_seconds % 86400),'%Hhrs %imins')); 
			IF usage_time IS NULL THEN
				SET usage_time = CONCAT('Operating theatre ', input_theatre_num, ' had no operations in ', given_year);
			END IF;
	END IF;
	
	RETURN (usage_time); 
END$$
DELIMITER ;
