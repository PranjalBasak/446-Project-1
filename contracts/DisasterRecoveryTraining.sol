pragma solidity ^0.8.0;

contract DisasterRecoveryTraining {
    enum TrainingType { first_aid, shelter_rebuild, food_safety }
    struct Admin {
        uint256 id;
        string name;
        uint256 age;
        uint256 balance;
        address account;
    }
    
    struct Trainer {
        uint256 id;
        string name;
        uint256 age;
        string gender;
        address account;
    }
    
    struct Participant {
        uint256 id;
        string name;
        uint256 age;
        string gender;
        string district;
        TrainingType training_interest;
        bool has_completed_training;
        uint256 balance;
        address account;
    }
    
    struct TrainingSlot {
        uint256 slotId;  // 0-47 representing 30-min slots in a day
        uint256 trainerId;
        uint256 participantId;
        bool isBooked;
    }
    uint256 private constant TOTAL_SLOTS_PER_DAY = 48; // 24 hours * 2 slots per hour
    uint256 private constant BOOKING_FEE = 1 ether; // Fixed booking fee
    uint256 private constant INITIAL_PARTICIPANT_BALANCE = 10 ether; // Initial balance for participants
    mapping(uint256 => Admin) private admins;
    mapping(uint256 => Trainer) private trainers;
    mapping(uint256 => Participant) private participants;
    mapping(uint256 => mapping(uint256 => TrainingSlot)) private trainerSlots; // trainerId => slotId => TrainingSlot
    uint256[] private adminIds; // Array to store all admin IDs for random selection
    mapping(address => uint256) private adminAddressToId;
    mapping(address => uint256) private trainerAddressToId;
    mapping(address => uint256) private participantAddressToId;
    
    modifier onlyAdmin() {
        uint256 adminId = adminAddressToId[msg.sender];
        require(adminId != 0 && admins[adminId].account == msg.sender, "Admin only");
        _;
    }
    
    modifier onlyParticipant(uint256 participantId) {
        require(participants[participantId].id != 0, "Participant not found");
        require(participants[participantId].account == msg.sender, "Participant only");
        _;
    }
    
    constructor() {
    }
    
    function registerAdmin(uint256 id, string memory name, uint256 age) external returns (uint256) {
        require(age > 0, "Invalid age");
        require(id > 0, "Invalid ID");
        require(admins[id].id == 0, "Admin ID already exists");
        require(adminAddressToId[msg.sender] == 0, "Address already registered as admin");
        
        admins[id] = Admin(id, name, age, 0, msg.sender);
        adminIds.push(id);
        adminAddressToId[msg.sender] = id;
        return id;
    }
    
    function registerTrainer(uint256 id, string memory name, uint256 age, string memory gender) external returns (uint256) {
        require(age > 0, "Invalid age");
        require(id > 0, "Invalid ID");
        require(trainers[id].id == 0, "Trainer ID already exists");
        require(trainerAddressToId[msg.sender] == 0, "Address already registered as trainer");
        
        trainers[id] = Trainer(id, name, age, gender, msg.sender);
        trainerAddressToId[msg.sender] = id;
        return id;
    }
    
    function registerParticipant(
        uint256 id,
        string memory name,
        uint256 age,
        string memory gender,
        string memory district,
        uint256 training_interest,
        bool has_completed_training
    ) external returns (uint256) {
        require(age > 0, "Invalid age");
        require(id > 0, "Invalid ID");
        require(participants[id].id == 0, "Participant ID already exists");
        require(training_interest <= 2, "Invalid training interest");
        require(participantAddressToId[msg.sender] == 0, "Address already registered as participant");
        
        participants[id] = Participant(
            id,
            name,
            age,
            gender,
            district,
            TrainingType(training_interest),
            has_completed_training,
            INITIAL_PARTICIPANT_BALANCE,
            msg.sender
        );
        participantAddressToId[msg.sender] = id;
        return id;
    }
    
    function updateParticipantData(uint256 participantId, uint256 newTrainingInterest, bool has_completed_training) external onlyAdmin {
        require(participants[participantId].id != 0, "Participant not found");
        require(newTrainingInterest <= 2, "Invalid training interest");
        
        Participant storage p = participants[participantId];
        require(!p.has_completed_training || has_completed_training, "Cannot change completed from true to false");
        
        p.training_interest = TrainingType(newTrainingInterest);
        p.has_completed_training = has_completed_training;
    }
    
    function bookTrainingSlot(uint256 trainerId, uint256 participantId, uint256 slotId) external onlyParticipant(participantId) returns (bool) {
        require(trainers[trainerId].id != 0, "Trainer not found");
        require(participants[participantId].id != 0, "Participant not found");
        require(participants[participantId].balance >= BOOKING_FEE, "Insufficient participant balance");
        require(adminIds.length > 0, "No admins available");
        require(slotId < TOTAL_SLOTS_PER_DAY, "Invalid slot ID");
        require(!trainerSlots[trainerId][slotId].isBooked, "Slot is already booked");
        trainerSlots[trainerId][slotId] = TrainingSlot(slotId, trainerId, participantId, true);
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, participantId))) % adminIds.length;
        uint256 selectedAdminId = adminIds[randomIndex];
        participants[participantId].balance -= BOOKING_FEE;
        admins[selectedAdminId].balance += BOOKING_FEE;
        
        return true;
    }
    
    function viewAdminBalance() external view returns (uint256[] memory adminIdList, uint256[] memory balanceList) {
        uint256 totalAdmins = adminIds.length;
        
        adminIdList = new uint256[](totalAdmins);
        balanceList = new uint256[](totalAdmins);
        
        for (uint256 i = 0; i < totalAdmins; i++) {
            uint256 adminId = adminIds[i];
            adminIdList[i] = adminId;
            balanceList[i] = admins[adminId].balance / 1 ether; // Convert wei to ether
        }
        
        return (adminIdList, balanceList);
    }
    
    function viewParticipantData(uint256 participantId) external view returns (
        uint256 id,
        string memory name,
        uint256 age,
        string memory gender,
        string memory district,
        uint256 training_interest,
        bool has_completed_training,
        uint256 balance
    ) {
        require(participants[participantId].id != 0, "Participant not found");
        
        Participant memory p = participants[participantId];
        return (
            p.id,
            p.name,
            p.age,
            p.gender,
            p.district,
            uint256(p.training_interest),
            p.has_completed_training,
            p.balance
        );
    }
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        if (value < 10) return string(abi.encodePacked("0", bytes1(uint8(48 + value))));
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function viewTrainerSchedule(uint256 trainerId) external view returns (
        uint256[] memory availableSlots,
        string[] memory timeRanges
    ) {
        require(trainers[trainerId].id != 0, "Trainer not found");
        uint256 availableCount = 0;
        for (uint256 i = 0; i < TOTAL_SLOTS_PER_DAY; i++) {
            if (!trainerSlots[trainerId][i].isBooked) {
                availableCount++;
            }
        }
        availableSlots = new uint256[](availableCount);
        timeRanges = new string[](availableCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < TOTAL_SLOTS_PER_DAY; i++) {
            if (!trainerSlots[trainerId][i].isBooked) {
                availableSlots[index] = i;
                uint256 startHour = i / 2;
                uint256 startMinute = (i % 2) * 30;
                uint256 endHour = startHour;
                uint256 endMinute = startMinute + 30;
                
                if (endMinute == 60) {
                    endHour++;
                    endMinute = 0;
                }
                timeRanges[index] = string(abi.encodePacked(
                    _toString(startHour), ":", 
                    startMinute == 0 ? "00" : "30", 
                    "-",
                    _toString(endHour), ":",
                    endMinute == 0 ? "00" : "30"
                ));
                
                index++;
            }
        }
        
        return (availableSlots, timeRanges);
    }
}