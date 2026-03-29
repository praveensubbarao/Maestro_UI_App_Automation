##Maestro UI App automaiton

#Important for setup of Virtual Device / Emulator / Simulator for testing
https://docs.maestro.dev/get-started/quickstart#android

#Commands available
https://docs.maestro.dev/reference/commands-available

##Learnings

# Error in simulator
The bundle ID com.apple.MobileAddressBook refers to the built-in iOS Contacts app. 
paul-samuels.com
paul-samuels.com
On iOS, Maestro implements clearState: true by uninstalling and reinstalling the app to ensure a fresh environment.
The iOS Simulator prohibits the uninstallation of core system apps like Contacts, which triggers the Uninstall prohibited error (code 22). 
Maestro Docs
Maestro Docs
How to Fix It
To resolve this, you must change how you launch the Contacts app in your .yaml flow:
Disable clearState: Change the parameter to false (or remove it, as it defaults to false for some commands).

# handle parsing error
Key Changes Made:
The First Dash: Every Maestro flow must start with a - (dash) for the first command after the --- separator.
Repeat Syntax: Added a colon after repeat: and commands:. The commands inside the repeat block must be indented further than the commands keyword itself.
Quotes for Strings: Added quotes around text like "All iPhone" and "Delete Contact". While not always required, it prevents the YAML parser from breaking on spaces or special characters.
Command Cleanup: Changed stopApp: to stopApp (it doesn't require a colon if no parameters follow).

