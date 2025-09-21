🎟 Raffle Contract Overview

This contract is a simple Raffle that uses Chainlink VRF v2 to randomly select a winner and can be automated via Chainlink Keepers.

⚡ Features

Players can participate in the raffle using ETH.

Random winner selection via Chainlink VRF v2.

Automated raffle execution based on time intervals via Chainlink Keepers.

Manages raffle states (OPEN & CALCULATING).

Secure payments and prevents underpayment entries.

🏗️ Variables & Structure
Raffle States
enum RaffleState {
    OPEN,
    CALCULATING
}

Key Variables

i_entranceFee: Entry fee to the raffle.

i_interval: Time interval between raffles.

s_players: List of players.

s_recentWinner: Most recent winner.

s_raffleState: Current state of the raffle.

🔹 Main Functions
1. enterRaffle

Players can enter the raffle by sending ETH.

2. checkUpkeep

Checks if the automated raffle execution conditions are met:

Required time has passed.

Raffle is open.

At least one player exists.

Contract balance is positive.

3. performUpkeep

If checkUpkeep is true, this function requests a random winner via VRF and sets the raffle state to CALCULATING.

4. fulfillRandomWords

Chainlink VRF callback function that selects the random winner and transfers the prize.

5. Getter Functions

For viewing contract info such as state, number of players, recent winner, etc.

⚠️ Errors

Raffle__UpkeepNotNeeded: Upkeep conditions not met.

Raffle__TransferFailed: Failed ETH transfer to the winner.

Raffle__SendMoreToEnterRaffle: Sent value is less than entrance fee.

Raffle__RaffleNotOpen: Raffle is not open.

📝 Usage

Deploy the contract on the desired network.

Set the VRF Coordinator address and SubscriptionId.

Players can enter using enterRaffle.

Chainlink Keeper automatically triggers raffle execution.
