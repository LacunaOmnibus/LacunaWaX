LacunaWaX
=========
A GUI for The Lacuna Expanse

Copyright 2012-2014 Jonathan D. Barton (tmtowtdi@gmail.com) 

STATUS
------
Installing and running the executable on Windows is reasonably straightforward and stable.
Running from source takes a bit of tweaking.  See the wiki for what information there is.

CAUTION
-------
LacunaWaX stores game account passwords in plain text.  Guard your lacuna\_app.sqlite file \- handing it to someone else for any reason is the same as handing that person not only your own account password, but also all of your recorded sitter passwords.

It is safe to send your lacuna\_log.sqlite file to someone else for debugging help if needed, as it contains no passwords.

RUNNING FROM SOURCE
-------------------
See the github wiki pages for help.  https://github.com/tmtowtdi/LacunaWaX/wiki

BRANCHES
--------
- master
    - ss_changes
        - Dealt Icy's station changes code that's now defunct.  But there may be some 
          usable ideas in here.
    - mass_delete_email
        - Deals with trash_messages_where().  The code on PT is still different from the 
          code on US1, but the mail deleter in this branch should be able to deal with the 
          US1 code as it stands now, and the PT code once it gets copied over to US1.
    - separate_bodies
        - empire->get_status() now includes status->{'stations'} and status->{'colonies'}.  
          This deals with that.



