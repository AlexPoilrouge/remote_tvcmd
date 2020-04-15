<?php
    $user = $_POST['user'];
    $request = $_POST['request'];
    $pass= $_POST['pass'];
    $args= $_POST['args'];
    
    $ip = $_SERVER['REMOTE_ADDR'];
    
    function pass_empty($arg_pass){
        if (empty($arg_pass)) {
	        echo "{\"request\":\"server-process\",\"status\":\"no-pass\"}";
	        return TRUE;
        }
        return FALSE;
    }
    
    if (empty($user)) {
    	echo "{\"request\":\"server-process\",\"status\":\"no-user\"}";
    }
    elseif (empty($ip)) {
    	echo "{\"request\":\"server-process\",\"status\":\"no-client-ip\"}";
    }
    else{
        $test= TRUE;
        $f_args= $args;
        switch ($request) {
        case "CONNECT":
            if ( ! pass_empty($pass) ){
                $f_args= $ip . ' ' . $pass;
            }
            else $test= FALSE;
        break;
        case "CHANGE_PASS":
            if ( ! pass_empty($pass) ){
                $f_args= $pass . ' ' . $args;
            }
            else $test= FALSE;
        break;
        case "REGISTER":
	        if ( ! pass_empty($pass) ) {
		        $f_args= $pass;
	        }
            else $test= FALSE;
        break;		
        case "DISCONNECT":
            $f_args= '';
        break;
        case "REQUEST":
            $f_args= $ip . ' ' . $args;
        break;
        default:
	        echo "{\"request\":\"server-process\",\"status\":\"unknown-command\"}";
	        $test= FALSE;
        }
        
        if ($test){
            $out= shell_exec("./worker.sh \"$user\" $request $f_args");
            
            if (empty($out)){
                echo "{\"request\":\"server-script\",\"status\":\"exec-error\"}";
            }
            else{
                echo "$out";
            }
        }
    }
?>
