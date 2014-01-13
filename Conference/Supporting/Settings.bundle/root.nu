(set ROOT (dict PreferenceSpecifiers:
                
                (array (dict Type:"PSGroupSpecifier"
                            Title:"Usergrid")
                       
                       (dict Type:"PSToggleSwitchSpecifier"
                            Title:"HTTPS"
                     DefaultValue:YES
                              Key:"usergrid_https")
                       
                       (dict Type:"PSTextFieldSpecifier"
                            Title:"Server"
                     KeyboardType:"Alphabet"
                              Key:"usergrid_server"
                     DefaultValue:"api.usergrid.com"
                         IsSecure:NO
               AutocorrectionType:"No"
           AutocapitalizationType:"None")
                       
                       (dict Type:"PSTextFieldSpecifier"
                            Title:"Org Name"
                     KeyboardType:"Alphabet"
                              Key:"usergrid_organization"
                     DefaultValue:"radtastical"
                         IsSecure:NO
               AutocorrectionType:"No"
           AutocapitalizationType:"None")
                       
                       (dict Type:"PSTextFieldSpecifier"
                            Title:"App Name"
                     KeyboardType:"Alphabet"
                              Key:"usergrid_application"
                     DefaultValue:"renaissance"
                         IsSecure:NO
               AutocorrectionType:"No"
           AutocapitalizationType:"None")
                       
                       (dict Type:"PSGroupSpecifier"
                            Title:"Twee")
                       
                       
                       )
                
                        StringsTable:"Root"))

((ROOT XMLPropertyListRepresentation) writeToFile:"Root.plist" atomically:NO)
