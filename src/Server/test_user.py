import pandas as pd
def testHyde(filename,jsonData,thresh):
    prYellow("USER TESTS FOR HYDE RUNNING:")
    print('―' * 30) 
    errormsg = ""
    errors = 0
    # TEST 1
    if jsonData == None or len(jsonData) == 0:
        print("Error: User did not upload file or uploaded empty file")
        errormsg = "Please upload a non empty hyde file"
        errors+=1
    else:
        prGreen("Passed: Test 1")
    dataset = pd.read_table(filename, delim_whitespace=True, header=None)
    # TEST 2
    if len(dataset.columns) != 8 and len(dataset.columns) != 21:
        print("Error: User has entered a wrong file format")
        print(len(dataset.columns))
        errormsg = "Please enter an appropriate Hyde file format"
        errors+=1
    else:
        prGreen("Passed: Test 2")
    try:
    # TEST 3
        if float(thresh) < 0:
            prRed("Failed Test 3: User has entered an invalid threshold")
            errormsg = "Please input a integer/decimal value for the threshold"
            errors+=1
        else:
            prGreen("Passed: Test 3")
    except:
        prRed("Failed Test 3 : User has entered an invalid threshold")
        errors+=1
        errormsg = "Please input a integer/decimal value for the threshold"

    if (errors>0):
     
        prRed("USER TESTS COMPLETED. FOUND " + str(errors) + ' ERRORS')
        prYellow("Error message being displayed: " + errormsg)
        print('―' * 30) 
    



def prRed(skk): print("\033[91m {}\033[00m" .format(skk))
def prGreen(skk): print("\033[92m {}\033[00m" .format(skk))
def prYellow(skk): print("\033[93m {}\033[00m" .format(skk))
def prLightPurple(skk): print("\033[94m {}\033[00m" .format(skk))
def prPurple(skk): print("\033[95m {}\033[00m" .format(skk))
def prCyan(skk): print("\033[96m {}\033[00m" .format(skk))
def prLightGray(skk): print("\033[97m {}\033[00m" .format(skk))
def prBlack(skk): print("\033[98m {}\033[00m" .format(skk))