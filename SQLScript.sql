-- Создание таблиц

CREATE TABLE YogaStudio (
    YogaStudioID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Address VARCHAR(200),
    Phone VARCHAR(20),
    Email VARCHAR(100)
);

CREATE TABLE Staff (
    StaffID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Phone VARCHAR(20),
    Role VARCHAR(50),
    YogaStudioID INT REFERENCES YogaStudio(YogaStudioID)
);

CREATE TABLE Instructor (
    InstructorID SERIAL PRIMARY KEY,
    Specialty VARCHAR(100),
    ExperienceYears INT,
    Certifications TEXT,
    StaffID INT REFERENCES Staff(StaffID)
);

CREATE TABLE Administrative (
    AdminID SERIAL PRIMARY KEY,
    Position VARCHAR(100),
    StaffID INT REFERENCES Staff(StaffID)
);

CREATE TABLE Room (
    RoomID SERIAL PRIMARY KEY,
    YogaStudioID INT REFERENCES YogaStudio(YogaStudioID),
    Name VARCHAR(50) NOT NULL,
    Capacity INT NOT NULL,
    Floor INT
);

CREATE TABLE Schedule (
    ScheduleID SERIAL PRIMARY KEY,
    YogaStudioID INT REFERENCES YogaStudio(YogaStudioID),
    DayOfWeek VARCHAR(20),
    StartTime TIME,
    EndTime TIME
);

CREATE TABLE Class (
    ClassID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    InstructorID INT REFERENCES Instructor(InstructorID),
    RoomID INT REFERENCES Room(RoomID),
    ScheduleID INT REFERENCES Schedule(ScheduleID),
    MaxCapacity INT
);

CREATE TABLE Client (
    ClientID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Phone VARCHAR(20),
    DateOfBirth DATE,
    YogaStudioID INT REFERENCES YogaStudio(YogaStudioID)
);

CREATE TABLE Membership (
    MembershipID SERIAL PRIMARY KEY,
    ClientID INT REFERENCES Client(ClientID),
    Type VARCHAR(50) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('active', 'inactive'))
);

CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    ClientID INT REFERENCES Client(ClientID),
    MembershipID INT REFERENCES Membership(MembershipID),
    Date DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Review (
    ReviewID SERIAL PRIMARY KEY,
    ClientID INT REFERENCES Client(ClientID),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment TEXT
);


-- ALTER-запросы

ALTER TABLE Client ADD COLUMN Email VARCHAR(100);
ALTER TABLE Membership ALTER COLUMN Type TYPE VARCHAR(100);
ALTER TABLE Instructor ADD COLUMN Email VARCHAR(100);
ALTER TABLE Room DROP COLUMN Floor;
ALTER TABLE Payment ADD COLUMN Method VARCHAR(20) DEFAULT 'card';


-- INSERT 
INSERT INTO YogaStudio (Name, Address, Phone, Email) VALUES
('Yoga Center Lotus', 'ул. Ленина, 15', '89001112233', 'lotus@yoga.com'),
('Yoga Harmony', 'ул. Пушкина, 8', '89002223344', 'harmony@yoga.com'),
('Yoga Flow', 'пр. Мира, 25', '89003334455', 'flow@yoga.com');

INSERT INTO Staff (FirstName, LastName, Phone, Role, YogaStudioID) VALUES
('Irina', 'Sheik', '893567927465', 'Instructor', 1),
('Kardi', 'B', '89093062566', 'Admin', 1),
('Emily', 'Witch', '89066069966', 'Instructor', 2),
('Tatiana', 'Bossdown', '89093062555', 'Admin', 2),
('Daria', 'Sveta', '89093062577', 'Instructor', 3),
('Emily', 'Newitch', '89066069965', 'Admin', 3);

INSERT INTO Instructor (Specialty, ExperienceYears, Certifications, StaffID) VALUES
('Hatha Yoga', 5, 'RYT-200', 1),
('Vinyasa Yoga', 7, 'RYT-500', 3);
('Hatha Yoga', 2, 'RYT-300', 5),

INSERT INTO Administrative (Position, StaffID) VALUES
('Receptionist', 2),
('Manager', 2),
('Administrator', 2);

INSERT INTO Room (YogaStudioID, Name, Capacity) VALUES
(1, 'Blue Hall', 20),
(2, 'Green Hall', 15),
(3, 'Sun Hall', 25);

INSERT INTO Schedule (YogaStudioID, DayOfWeek, StartTime, EndTime) VALUES
(1, 'Monday', '09:00', '10:30'),
(2, 'Wednesday', '18:00', '19:30'),
(3, 'Saturday', '11:00', '12:30');

INSERT INTO Class (Name, InstructorID, RoomID, ScheduleID, MaxCapacity) VALUES
('Morning Hatha', 1, 1, 1, 20),
('Evening Vinyasa', 2, 2, 2, 15),
('Weekend Flow', 3, 3, 3, 25);

INSERT INTO Client (FirstName, LastName, Phone, DateOfBirth, YogaStudioID) VALUES
('Maria', 'Petrova', '89991112233', '1998-05-21', 1),
('Olga', 'Sidorova', '89992223344', '2000-07-11', 2),
('Natalia', 'Fedorova', '89993334455', '1995-03-15',3);

INSERT INTO Membership (ClientID, Type, StartDate, EndDate, Status) VALUES
(1, 'Monthly', '2025-10-01', '2025-10-31', 'active'),
(2, 'Yearly', '2025-01-01', '2025-12-31', 'active'),
(3, 'Monthly', '2025-02-01', '2025-02-28', 'inactive');

INSERT INTO Payment (ClientID, MembershipID, Date, Amount) VALUES
(1, 1, '2025-10-01', 3000),
(2, 2, '2025-01-05', 25000),
(3, 3, '2025-02-01', 3000);

INSERT INTO Review (ClientID, Rating, Comment) VALUES
(1, 5, 'Очень понравилось!'),
(2, 4, 'Хорошо, но хотелось бы больше хатхи'),
(3, 5, 'Супер студия!');



-- UPDATE-запросы
UPDATE Client SET Phone = '89995556677' WHERE ClientID = 1;
UPDATE Membership SET Status = 'inactive' WHERE MembershipID = 2;
UPDATE Instructor SET ExperienceYears = 8 WHERE InstructorID = 1;
UPDATE Room SET Capacity = 30 WHERE RoomID = 3;
UPDATE Payment SET Amount = 2800 WHERE PaymentID = 3;


