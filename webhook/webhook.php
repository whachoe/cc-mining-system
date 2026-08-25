<?php

var_dump($_REQUEST);


// Get the body of the request and print it on the screen
echo "Body:";
echo file_get_contents('php://input');

