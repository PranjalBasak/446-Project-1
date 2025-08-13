// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DisasterRecoveryTraining {
    // Training types
    enum TrainingType { first_aid, shelter_rebuild, food_safety }
    
    // User structs
    struct Admin {
        uint256 id;
        string name;
        uint256 age;
        uint256 balance;
    }
    
    struct Trainer {
        uint256 id;
        string name;
        uint256 age;
        string gender;
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
    }
    
    struct TrainingSlot {
        uint256 slotId;  // 0-47 representing 30-min slots in a day
        uint256 trainerId;
        uint256 participantId;
        bool isBooked;
    }
    
    // State variables
    uint256 private adminCount;
    uint256 private trainerCount;
    uint256 private participantCount;
    uint256 private constant TOTAL_SLOTS_PER_DAY = 48; // 24 hours * 2 slots per hour
    uint256 private constant BOOKING_FEE = 1 ether; // Fixed booking fee
    uint256 private constant INITIAL_PARTICIPANT_BALANCE = 10 ether; // Initial balance for participants
    
    // Data storage
    mapping(uint256 => Admin) private admins;
    mapping(uint256 => Trainer) private trainers;
    mapping(uint256 => Participant) private participants;
    mapping(uint256 => mapping(uint256 => TrainingSlot)) private trainerSlots; // trainerId => slotId => TrainingSlot
    uint256[] private adminIds; // Array to store all admin IDs for random selection
    
    // Events removed as requested
    
    constructor() {
        // Initialize counters
        adminCount = 0;
        trainerCount = 0;
        participantCount = 0;
        // Contract starts with no default admin
        // Admins must be registered using registerAdmin function
    }
    
    // ===== CORE FUNCTIONALITY 1: REGISTRATION (For All) =====
    
    function registerAdmin(uint256 id, string memory name, uint256 age) external returns (uint256) {
        require(age > 0, "Invalid age");
        require(id > 0, "Invalid ID");
        require(admins[id].id == 0, "Admin ID already exists");
        
        admins[id] = Admin(id, name, age, 0);
        adminIds.push(id);
        adminCount++;
        return id;
    }
    
    function registerTrainer(uint256 id, string memory name, uint256 age, string memory gender) external returns (uint256) {
        require(age > 0, "Invalid age");
        require(id > 0, "Invalid ID");
        require(trainers[id].id == 0, "Trainer ID already exists");
        
        trainers[id] = Trainer(id, name, age, gender);
        trainerCount++;
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
        
        participants[id] = Participant(
            id,
            name,
            age,
            gender,
            district,
            TrainingType(training_interest),
            has_completed_training,
            INITIAL_PARTICIPANT_BALANCE
        );
        participantCount++;
        return id;
    }
    
    // ===== CORE FUNCTIONALITY 2: DATA UPDATE (For Admin Only) =====
    
    function updateParticipantData(uint256 participantId, uint256 newTrainingInterest, bool has_completed_training) external {
        require(participants[participantId].id != 0, "Participant not found");
        require(newTrainingInterest <= 2, "Invalid training interest");
        
        Participant storage p = participants[participantId];
        require(!p.has_completed_training || has_completed_training, "Cannot change completed from true to false");
        
        p.training_interest = TrainingType(newTrainingInterest);
        p.has_completed_training = has_completed_training;
    }
    
    // ===== CORE FUNCTIONALITY 3: BOOKING (For Participants Only) =====
    
    function bookTrainingSlot(uint256 trainerId, uint256 participantId, uint256 slotId) external returns (bool) {
        require(trainers[trainerId].id != 0, "Trainer not found");
        require(participants[participantId].id != 0, "Participant not found");
        require(participants[participantId].balance >= BOOKING_FEE, "Insufficient participant balance");
        require(adminIds.length > 0, "No admins available");
        require(slotId < TOTAL_SLOTS_PER_DAY, "Invalid slot ID");
        
        // Check if the specific slot is already booked - if so, fail the transaction
        require(!trainerSlots[trainerId][slotId].isBooked, "Slot is already booked");
        
        // Book the specific slot
        trainerSlots[trainerId][slotId] = TrainingSlot(slotId, trainerId, participantId, true);
        
        // Select random admin to receive the fee
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, participantId))) % adminIds.length;
        uint256 selectedAdminId = adminIds[randomIndex];
        
        // Deduct booking fee from participant and add to random admin balance
        participants[participantId].balance -= BOOKING_FEE;
        admins[selectedAdminId].balance += BOOKING_FEE;
        
        return true;
    }
    
    // ===== CORE FUNCTIONALITY 4: VIEW SCHEDULES (For All) =====
    
    
    
    // ===== ADMIN BALANCE FUNCTIONALITY =====
    
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
    
    // ===== PARTICIPANT DATA FUNCTIONALITY =====
    
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
    
    // Simple integer to string conversion
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
        
        // Count available slots
        uint256 availableCount = 0;
        for (uint256 i = 0; i < TOTAL_SLOTS_PER_DAY; i++) {
            if (!trainerSlots[trainerId][i].isBooked) {
                availableCount++;
            }
        }
        
        // Fill arrays with available slots and their time ranges
        availableSlots = new uint256[](availableCount);
        timeRanges = new string[](availableCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < TOTAL_SLOTS_PER_DAY; i++) {
            if (!trainerSlots[trainerId][i].isBooked) {
                availableSlots[index] = i;
                
                // Calculate time range inline
                uint256 startHour = i / 2;
                uint256 startMinute = (i % 2) * 30;
                uint256 endHour = startHour;
                uint256 endMinute = startMinute + 30;
                
                if (endMinute == 60) {
                    endHour++;
                    endMinute = 0;
                }
                
                // Format time string (simplified)
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