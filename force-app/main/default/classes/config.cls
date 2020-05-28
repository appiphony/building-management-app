public with sharing class config {
    //map our employee status to b2w employee status
    public static Map<String, String> back2workStatusByWdcTestStatus = new Map<String, String> {
        'Remote' => 'Remote Work Only',
        'Available' => 'Available to Work',
        'Unavailable' => 'Unavailable',
        'Unknown' => 'Unknown'
    };

    //
    public static Map<String, String> locationFieldByBuildingField = new Map<String, String> {
        'Name' => 'Name',
        'wdctest__Location__Latitude__s' => 'Latitude',
        'wdctest__Location__Longitude__s' => 'Longitude'
    };

    public static Map<String, String> locationFieldByFloorField = new Map<String, String> {
        'Name' => 'Name'
    };

    public static Map<String, String> b2WEmployeeFieldByemployeeField = new Map<String, String> {
        'wdctest__First_Name__c' => 'FirstName',
        'wdctest__Last_Name__c' => 'LastName',
        'wdctest__status__c' => 'CurrentWellnessStatus'
    };

    public static List<Decimal> frequencies = new List<Decimal>{0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2};

    public static List<Integer> floorsToInsert = new List<Integer>{4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,60,61};

    public static List<String> employeeFirstNames = new List<String>{'Cynthia', 'Alessia', 'Fred', 'Makena', 'Matt', 'Doris', 'Samara', 'Elise', 'Owen', 'Eduardo', 'Caydence', 'Joseph', 'Aiden', 'Anthony', 'Benny', 'Liliana', 'Summer', 'Benny', 'Laila', 'Percy', 'Chad', 'Michael', 'Danielle', 'Logan', 'Denny', 'Katelyn', 'Gabriel', 'Chadwick', 'Cedrick', 'Michaela', 'Ron', 'Julius', 'Dalia', 'Josh', 'Stephanie', 'Johnathan', 'Valentina', 'Josephine', 'Barry', 'Enoch', 'Summer', 'Erick', 'Lauren', 'Mina', 'Liam', 'Camila', 'Chad', 'Ramon', 'Elijah', 'Michelle', 'Peter', 'David', 'Amy', 'Logan', 'Fiona', 'Hayden', 'Camden', 'Doris', 'Chris', 'Christine', 'Melanie', 'Peter', 'Hank', 'Mackenzie', 'Chris', 'Savannah', 'Katelyn', 'Tony', 'Ruby', 'Lucas', 'Kieth', 'Leroy', 'Jacob', 'Javier', 'Rita', 'Johnny', 'Abdul', 'John', 'Francesca', 'Liam', 'Clint', 'Chris', 'Daphne', 'Rosie', 'Zoe', 'Jazmin', 'Kurt', 'Kate', 'Britney', 'Abdul', 'Skylar', 'Ethan', 'Doug', 'Ron', 'Joy', 'Mackenzie', 'Rick', 'Eden', 'Callie', 'Adina', 'Florence', 'Catherine', 'Esmeralda', 'Jackeline', 'Ryan', 'Ramon', 'Henry', 'Rachael', 'Henry', 'Kamila', 'Adina', 'Colleen', 'Manuel', 'Andrea', 'Clint', 'Adeline', 'Enoch', 'Eduardo', 'Phillip', 'Keira', 'Tara', 'Stephanie', 'Percy', 'Jayden', 'Owen', 'Robyn', 'Christine', 'Juliet', 'Cynthia', 'Marilyn', 'Felicity', 'Charlotte', 'Kurt', 'Johnny', 'Jamie', 'Ronald', 'Greta', 'Rufus', 'Oliver', 'Valentina', 'Sebastian', 'Melanie', 'Mark', 'Lillian', 'Ally', 'Clarissa', 'Sebastian', 'Johnny', 'Leanne', 'Makena', 'Carrie', 'Erick', 'Lucy', 'Joy', 'Beatrice', 'Tom', 'William', 'Bristol', 'George', 'Liam', 'Analise', 'Chadwick', 'Tom', 'Winnie', 'Leroy', 'Joseph', 'Sienna', 'Domenic', 'Maribel', 'Ronald', 'Maia', 'Melinda', 'Rachael', 'Sasha', 'Jayden', 'Aiden', 'Noah', 'Aiden', 'Daniel', 'Harvey', 'Julia', 'Dasha', 'Oliver', 'Leroy', 'Hayden', 'Nate', 'Doug', 'Matt', 'Brad', 'Logan', 'Anthony', 'Mark', 'Margaret', 'Norah', 'Barry', 'Lucas', 'Doug', 'Alexander', 'Elijah', 'Luke'};
    public static List<String> employeeLastNames = new List<String>{'Oswald', 'Thomas', 'Lewin', 'Benson', 'Isaac', 'Phillips', 'Bryant', 'Broomfield', 'Alexander', 'Potts', 'Simpson', 'Uddin', 'Oakley', 'Dowson', 'Vallory', 'Jordan', 'Oswald', 'Allen', 'Butler', 'Rehman', 'Button', 'Mcleod', 'Rothwell', 'Lindsay', 'Little', 'Harrison', 'Collis', 'Utterson', 'Needham', 'Briggs', 'Haines', 'Stewart', 'Morris', 'Potts', 'Parsons', 'Scott', 'Moore', 'Thomas', 'Phillips', 'Ross', 'Locke', 'Reid', 'Nanton', 'Lynn', 'Forester', 'Greenwood', 'Collis', 'James', 'Morley', 'Gray', 'Wright', 'Bell', 'Pope', 'Mitchell', 'Jennson', 'Johnson', 'Yard', 'Smith', 'Clarkson', 'Cowan', 'Gordon', 'Nurton', 'Haines', 'Mcgee', 'Miller', 'Steer', 'Horton', 'John', 'Ward', 'Mcgee', 'Baldwin', 'Taylor', 'Powell', 'Dobson', 'Wilkinson', 'Hepburn', 'Thomson', 'Nobbs', 'Miller', 'Preston', 'Clarke', 'Donovan', 'Jenkin', 'Uddin', 'Thatcher', 'Poole', 'Allen', 'Hudson', 'Saunders', 'Woodley', 'Shelton', 'Amstead', 'Baxter', 'Alcroft', 'Mcnally', 'John', 'Blackwall', 'Hopkinson', 'Vass', 'Taylor', 'Eddison', 'Nielson', 'Raven', 'Milner', 'Tyler', 'Ellis', 'Andrews', 'Fox', 'Ballard', 'Townend', 'Evans', 'Brown', 'Farrow', 'Locke', 'Poulton', 'Wright', 'Nurton', 'Furnell', 'Shepherd', 'Hopkinson', 'Rycroft', 'Bright', 'Weldon', 'Umney', 'Crawley', 'Evans', 'Simpson', 'Carter', 'Jones', 'Curtis', 'Mooney', 'Rothwell', 'Spencer', 'Yard', 'Lane', 'Hancock', 'Price', 'Simpson', 'Weatcroft', 'Dubois', 'Ellis', 'Drake', 'Todd', 'Fleming', 'Swift', 'Jarvis', 'Ryan', 'Spencer', 'Tutton', 'Stewart', 'Hopkins', 'Leigh', 'Ryan', 'Blackwall', 'Walker', 'Rigg', 'Andrews', 'Collingwood', 'Locke', 'Thompson', 'Silva', 'Mcgregor', 'Rees', 'Ryan', 'Quinn', 'Cattell', 'Hudson', 'Shields', 'Farrant', 'Trent', 'Drake', 'Hopkins', 'Gordon', 'Gibson', 'Tailor', 'Fall', 'Nielson', 'Knott', 'Ventura', 'Russell', 'Broomfield', 'Irving', 'Skinner', 'Fields', 'Milner', 'Duvall', 'Cork', 'Clark', 'Rothwell', 'Kelly', 'Coll', 'Whinter', 'Amstead', 'Rogers', 'Vangness', 'Roth', 'Tate', 'Holmes', 'Gallacher', 'Janes'};
}