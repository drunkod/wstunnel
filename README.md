Get started by customizing your environment (defined in the .idx/dev.nix file) with the tools and IDE extensions you'll need for your project!

Learn more at https://developers.google.com/idx/guides/customize-idx-env

Go to the "Interfaces" Tab: In the Ligolo web UI, click on the Interfaces tab at the top.
Create a New, Empty Interface:
Click the "Add New" button.
A box will appear. Give your interface a simple name, like manual-tunnel.
Click "Create".
You will now see manual-tunnel in the list with an "Active" state but no routes. This is correct.
Manually Add the Correct Route:
On the row for your manual-tunnel, find the "Add Route" button in the "ACTIONS" column. It looks like a small speech bubble icon (🗨️). Click it.
A box will pop up asking for the route.
Enter the main network you want to access: 10.88.0.0/16
Click "Add".
You will now see your manual-tunnel interface with the 10.88.0.0/16 route listed next to it.
Bind the Agent to the New Interface:
Go back to the "Agents" tab.
Your agent's status is Stopped.
In the "ACTIONS" column, click the Power-On button (the one that looks like a ⏻ symbol).
A menu will appear. It will ask you to which interface you want to bind the tunnel. Select your manual-tunnel.
The tunnel will now start. The status should change to Tunneling and it will work correctly because you have bypassed the bug in the Autoroute feature. You can now proceed to ping and nmap the 10.88.0.0/16 network.

agent -connect node199819-env-9764176-clone108363.mircloud.host:11113 -ignore-cert -v