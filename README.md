# ExecuteProcessTransitionAction

A generic agent custom module that executes any process transition action you like.

## Requirements

- Znuny 6.3.4 or similar.

## Usage

- Copy file ```ExecuteProcessTransitionAction.pm``` module to ```Custom/Kernel/System/GenericAgent/``` folder.
- Create a process transition (could be a mock one) for log purposes.
- Create the process transition action(s) you would like to run.
- Create a new generic agent using this custom module.

## Parameters

- TransitionActionEntityIDs (required): a comma separated list with the process transtion action entity IDs you would like to run.
- TransitionEntityID (required): a process transition for log purposes (its condition will not be avaliated).
- HistoryName (required): a text for the ticket history only for audit purposes.

## Observation

- The ticket that triggers the generic agent must be a process ticket.
- I recommend to document the workflow in a mock workflow inside the process definition.