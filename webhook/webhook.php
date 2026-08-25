<?php

//var_dump($_REQUEST);


// Get the body of the request and print it on the screen
file_put_contents('mc.log', file_get_contents('php://input'), FILE_APPEND);

