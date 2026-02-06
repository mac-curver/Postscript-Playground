#!/bin/sh

#  ShowLogFor.sh
#  Postscript Playground
#
#  Created by LegoEsprit on 27.01.24.
# chmod +x ShowLogFor.sh
sudo log stream --predicate 'subsystem == "de.LegoEsprit.Postscript-Playground"' | awk 'NR>2 {print substr($0,12,15) " T:" substr($0,index($0,"00 ")+3, 8)  substr($0, index($0,"]")+1) }'
#  
