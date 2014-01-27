;; routes.nu
;;
;;  Created by Tim Burks
;;  Copyright (c) 2014 Radtastical Inc. All rights reserved.
;;
;;  Licensed under the Apache License, Version 2.0 (the "License");
;;  you may not use this file except in compliance with the License.
;;  You may obtain a copy of the License at
;;
;;  http://www.apache.org/licenses/LICENSE-2.0
;;
;;  Unless required by applicable law or agreed to in writing, software
;;  distributed under the License is distributed on an "AS IS" BASIS,
;;  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;  See the License for the specific language governing permissions and
;;  limitations under the License.

(render "main"
        (dict tabs:(array "download")))

(render "download"
        (dict title:"#renio"
    button_topright:(dict image:"01-refresh.png" action:"modal RadDownloadViewController")
           sections:(array (dict rows:(array
                                            (dict image:(dict filename:"icon-large.png" position:"top")
                                               markdown:"# Download Required\n\nThis app must download additional information before it can be used. To proceed, please be sure that you are connected to the internet."
                                             attributes:"centered")
                                            (dict markdown:"## Begin Downloading"
                                                attributes:"centered"
                                                    action:"modal RadDownloadViewController"))))))

(def row-for-sponsor (sponsor)
     (set row (dict markdown:(+ "*" (sponsor acknowledgement:)
                                "*\n\n# "
                                (sponsor title:)
                                "\n\n"
                                (sponsor summary:))
                  attributes:"default"
                      action:(+ "push sponsors/" (sponsor name:))))
     (if (and (set image (sponsor image:))
              (image isKindOfClass:NSString))
         (row image:(dict filename:(+ "" (sponsor year:) "_" image)
                          position:"left"
                              mask:"none")))
     row)

(render "sponsors"
        (set sponsor-rows (array))
        (set donor-rows (array))
        (((Conference sharedInstance) sponsors) each:
         (do (sponsor)
             ((if (sponsor paid:)
                  (then sponsor-rows)
                  (else donor-rows)) addObject:(row-for-sponsor sponsor))))
        (dict title:"Sponsors"
              image:"190-bank.png"
            refresh:(do (controller)
                        (dict sections:(array (dict header:(dict text:"Financial Supporters")
                                                      rows:sponsor-rows)
                                              (dict header:(dict text:"Prize Donors")
                                                      rows:donor-rows))))))

(render "sponsors/sponsorid:"
        (set sponsor ((Conference sharedInstance) sponsorWithName:sponsorid))
        (set rows (array))
        (set markdown (+ "# " (sponsor title:) "\n\n"
                         "*" (sponsor summary:) "*\n\n"
                         (sponsor description:) "\n\n"))
        (set row (dict markdown:markdown
                     attributes:"spaced"))
        (if (and (set image (sponsor image:))
                 (image isKindOfClass:NSString))
            (row image:(dict filename:(+ "" (sponsor year:) "_" image)
                             position:"top"
                                 mask:"none")))
        (rows addObject:row)
        (if (and (set twitterid (sponsor twitterid:))
                 (twitterid isKindOfClass:NSString))
            (rows addObject:(dict markdown:(+ "On Twitter\n## @" twitterid)
                                    action:(+ "modal http://twitter.com/" twitterid))))
        (if (and (set link (sponsor url:))
                 (link isKindOfClass:NSString))
            (rows addObject:(dict markdown:(+ "On the web\n## " link)
                                    action:(+ "modal " link))))
        (dict title:(sponsor title:)
          separator:"none"
           sections:(array (dict rows:rows))))

(set newsDayFormatter (NSDateFormatter new))
(newsDayFormatter setDateFormat:"EEEE MMM dd, yyyy")
(newsDayFormatter setTimeZone:(NSTimeZone timeZoneWithName:"PST"))

(def row-for-news (item)
     (set itemDate (NSDate dateWithTimeIntervalSince1970:(/ (item created:) 1000)))
     (set markdown (+ "# "
                      (item title:)
                      "\n\n*"
                      (item summary:)
                      "*\n\n"
                      (newsDayFormatter stringFromDate:itemDate)))
     (set row (dict markdown:markdown
                  attributes:"small"
                      action:"push news/#{(item name:)}"))
     (if (and (set image (item image:))
              (image isKindOfClass:NSString))
         (row image:(dict filename:image
                          position:"left"
                              mask:"square")))
     row)

(render "news"
        (dict title:"News"
              image:"166-newspaper.png"
            refresh:(do (controller)
                        (dict sections:(array (dict rows:((((Conference sharedInstance) news) map:
                                                           (do (item) (row-for-news item))))))))))

(render "news/itemid:"
        (set item ((Conference sharedInstance) newsItemWithName:itemid))
        (set itemDate (NSDate dateWithTimeIntervalSince1970:(/ (item created:) 1000)))
        (set rows (array))
        ;; item header
        (set markdown (+ "# " (item title:) "\n\n"
                         "*" (item summary:) "*\n\n"
                         (newsDayFormatter stringFromDate:itemDate)))
        (set row (dict markdown:markdown
                     attributes:"default"))
        (if (and (set image (item image:))
                 (image isKindOfClass:NSString))
            (row image:(dict filename:image
                             position:"top"
                                 mask:"none")))
        (rows addObject:row)
        ;; item body
        (rows addObject:(dict markdown:(item details:)
                            attributes:"spaced"))
        ;; optional link
        (if (and (set URL (item url:))
                 (URL isKindOfClass:NSString))
            (rows addObject:(dict markdown:(+ "## On the web\n**" URL "**")
                                    action:(+ "modal " URL))))
        (dict title:(item title:)
          separator:"none"
           sections:(array (dict rows:rows))))

(render "sessions/year:/day/day:"
        (set title "#{year} Sessions")
        (set key "#{year}_#{day}")
        (set sessions (((Conference sharedInstance) sessionsByDay) objectForKey:key))
        (dict title:title
           sections:(array (dict rows:(sessions map:
                                                (do (session) (row-for-session session)))))))

(render "sessions/year:/sessionname:"
        (set timezone (NSTimeZone timeZoneWithName:"PST"))
        (set dateParser (NSDateFormatter new))
        (dateParser setDateFormat:"yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        (set timeFormatter (NSDateFormatter new))
        (timeFormatter setDateFormat:"hh:mm a")
        (timeFormatter setTimeZone:timezone)
        (set dayFormatter (NSDateFormatter new))
        (dayFormatter setDateFormat:"EEEE")
        (dayFormatter setTimeZone:timezone)
        
        (set session ((Conference sharedInstance) sessionWithName:sessionname))
        (set sections (array))
        (set sessionTime (dateParser dateFromString:(session time:)))
        (set sessionText (+ (dayFormatter stringFromDate:sessionTime) ", "
                            (timeFormatter stringFromDate:sessionTime) ", "
                            (session duration:) " minutes\n"
                            "# " (session title:) "\n\n"
                            "*" (session summary:) "*\n\n \n\n"
                            (session description:)))
        (sections addObject:(dict rows:(array (dict markdown:sessionText))))
        
        (set speakers (array))
        ((array "speaker_1"
                "speaker_2"
                "speaker_3"
                "speaker_4"
                "speaker_5"
                "speaker_6") each:
         (do (key)
             (set speakerid (session objectForKey:key))
             (if (and (speakerid isKindOfClass:NSString)
                      (set speaker ((Conference sharedInstance) speakerWithId:speakerid)))
                 (speakers addObject:speaker))))
        
        (set moderators (array))
        ((array "moderator") each:
         (do (key)
             (set speakerid (session objectForKey:key))
             (if (and (speakerid isKindOfClass:NSString)
                      (set speaker ((Conference sharedInstance) speakerWithId:speakerid)))
                 (moderators addObject:speaker))))
        (if (speakers count)
            (sections addObject:(dict header:(dict text:"Speakers")
                                        rows:(speakers map:
                                                       (do (speaker)
                                                           (row-for-speaker speaker))))))
        (if (moderators count)
            (sections addObject:(dict header:(dict text:"Moderator")
                                        rows:(moderators map:
                                                         (do (speaker)
                                                             (row-for-speaker speaker))))))
        (set page (dict title:(+ "" (session year:) " Session")
                     sections:sections
              button_topright:(dict text:"Survey"
                                  action:(+ "modal survey/" (session name:)))))
        page)

(def row-for-session (session)
     (set timezone (NSTimeZone timeZoneWithName:"PST"))
     (set dateParser (NSDateFormatter new))
     (dateParser setDateFormat:"yyyy-MM-dd'T'HH:mm:ss.SSSZ")
     (set sessionTime (dateParser dateFromString:(session time:)))
     (set timeFormatter (NSDateFormatter new))
     (timeFormatter setDateFormat:"EEEE, hh:mm a")
     (timeFormatter setTimeZone:timezone)
     (set markdownString ((NSMutableString alloc) init))
     (markdownString appendString:(timeFormatter stringFromDate:sessionTime))
     (markdownString appendString:"\n\n")
     (if ((session keynote:) intValue)
         (then (markdownString appendString:"## Keynote: "))
         (else (markdownString appendString:"## ")))
     (markdownString rad_safelyAppendString:(session title:))
     (markdownString appendString:"\n\n")
     (if (markdownString rad_safelyAppendString:(session summary:))
         (markdownString appendString:"\n\n"))
     (dict markdown:markdownString
             action:(+ "push sessions/" (session year:) "/" (session name:))))

(def row-for-speaker (speaker)
     (set fullname (+ (speaker name_first:) " " (speaker name_last:)))
     (set markdown (+ "## " fullname "\n\n"))
     (if (markdown rad_safelyAppendString:(speaker title:))
         (markdown appendString:"\n\n"))
     (if (markdown rad_safelyAppendString:(speaker affiliation:))
         (markdown appendString:"\n\n"))
     (set filename (+ (((speaker name:) lowercaseString)
                       stringByReplacingOccurrencesOfString:" " withString:"_") ".jpg"))
     (dict markdown:markdown
              image:(dict filename:filename
                          position:"left"
                              mask:"circle")
             action:(+ "push speaker/" (speaker year:) "/" (speaker name:))))

(def row-for-link (link)
     (set markdown "*")
     (markdown rad_safelyAppendString:(link kind:))
     (markdown appendString:"*")
     (markdown appendString:"\n\n")
     (markdown appendString:"## ")
     (markdown rad_safelyAppendString:(link title:))
     (markdown appendString:"\n\n")
     (markdown appendString:"*")
     (markdown rad_safelyAppendString:(link url:))
     (markdown appendString:"*")
     (markdown appendString:"\n\n")
     (dict markdown:markdown
             action:(+ "modal " (link url:))))

(render "speakers/year:"
        (set sections (array))
        (((Conference sharedInstance) alphabet) eachWithIndex:
         (do (letter i)
             (set group (((Conference sharedInstance) alphabetizedSpeakersForYear:(year intValue)) objectAtIndex:i))
             (sections addObject:(dict header:(dict text:letter)
                                         rows:(group map:(do (speaker)
                                                             (row-for-speaker speaker)))))))
        (dict title:"Speakers and Organizers"
              index:((Conference sharedInstance) alphabet)
           sections:sections))

(render "speaker/year:/speakername:"
        (set speaker ((Conference sharedInstance) speakerWithName:speakername))
        (set fullname (+ (speaker name_first:) " " (speaker name_last:)))
        (set subtitle (+ "## " fullname "\n\n"))
        (if (subtitle rad_safelyAppendString:(speaker title:))
            (subtitle appendString:"\n\n"))
        (if (subtitle rad_safelyAppendString:(speaker affiliation:))
            (subtitle appendString:"\n\n"))
        (set filename (+ (((speaker name:) lowercaseString)
                          stringByReplacingOccurrencesOfString:" " withString:"_") ".jpg"))
        (set sections (array))
        (sections addObject:(dict rows:(array (dict kind:"image"
                                                   image:(dict filename:filename
                                                               position:"top")
                                                markdown:subtitle
                                              attributes:"right"))))
        (set hometown (speaker hometown:))
        (if (hometown isKindOfClass:NSString)
            (sections addObject:(dict header:(dict text:"Hometown")
                                        rows:(array (dict markdown:hometown)))))
        (set details (speaker details:))
        (if (details isKindOfClass:NSString)
            (sections addObject:(dict header:(dict text:"Biography")
                                        rows:(array (dict markdown:details)))))
        (set links (speaker speaker_links:))
        (if (and links
                 (links isKindOfClass:NSArray)
                 (links count))
            (set rows (links map:
                             (do (link)
                                 (row-for-link link))))
            (sections addObject:(dict header:(dict text:(+ "Follow " (speaker name_first:)))
                                        rows:rows)))
        (dict title:fullname
           sections:sections))

(render "survey/surveyid:"
        (if (eq surveyid "2014_conference")
            (then (set surveyname surveyid)
                  (set session nil))
            (else (set surveyname "2014_session")
                  (set session ((Conference sharedInstance) sessionWithName:surveyid))))
        (set survey ((Conference sharedInstance) surveyWithName:surveyname))
        (set questions (survey surveyquestions:))
        (set sections (array))
        (set rows (array))
        (if session
            (rows addObject:(dict markdown:(+ "## "
                                              (session title:)
                                              "\n\n"
                                              (session summary:)
                                              "\n\n"))))
        (set section (dict header:(dict text:"All survey responses are anonymous.")
                             rows:rows))
        (sections addObject:section)
        (questions eachWithIndex:
                   (do (question i)
                       (sections addObject:(dict header:(dict text:"Q#{(+ i 1)}")
                                                   rows:(array (dict markdown:(question question:))
                                                               (dict input:(dict type:(question responsetype:)
                                                                                   id:"q#{(+ i 1)}")))))))
        
        (dict title:(survey title:)
               form:surveyid
          separator:"none"
    button_topright:(dict text:"Close"
                        action:(do (controller)
                                   ((RadFormDataManager sharedInstance) save)
                                   (set surveyResponse (((RadFormDataManager sharedInstance) forms) objectForKey:surveyid))
                                   (set fields (dict name:(+ (RadUUID sharedIdentifier) "-" surveyid)
                                                   device:(RadUUID sharedIdentifier)
                                                   survey:surveyid
                                                     body:surveyResponse))
                                   (set saveRequest ((UGConnection sharedInstance)
                                                     updateEntity:(fields name:)
                                                     inCollection:"surveyresponses"
                                                     withValues:fields))
                                   (RadHTTPClient connectWithRequest:saveRequest completionHandler:nil)
                                   (controller dismissViewControllerAnimated:YES completion:nil)))
           sections:sections))

(render "twee"
        (dict title:"Twee"
              image:"209-twitter.png"
          separator:"none"
         controller:"TwitterMobViewController"
     button_topleft:(dict image:"209-twitter.png"
                         action:(do (controller) (controller presentAccountViewController)))
    button_topright:(dict text:"History"
                        action:(do (controller) (controller presentHistoryViewController)))
           sections:(array (dict rows:(array (dict markdown:"Discover the people around you with **Twee**.\n\nTwee uses Bluetooth LE and your Twitter username to announce your presence to other nearby people. It also scans for other Twee users and maintains a history of people it discovers.\n\nEvery time you use the #renio app, Twee automatically records new people it discovers. It keeps a running score based on the number of times a person is nearby and how close they are to you.\n\nTwee also provides a real time display of nearby Twee users, sorted by their proximity to you.\n\nAt the end of the conference you will have a historical record of all of the Renaissance attendees you were near, sorted by how often they were in your vicinity.\n\nNow look up and meet them!"
                                                 attributes:"spaced")
                                             (dict markdown:"## Start Now"
                                                 attributes:"centered"
                                                     action:(do (controller) (controller presentAccountViewController)))
                                             (dict markdown:"*Your personal history of nearby Twee users is stored locally in this app only. It is never uploaded or shared.*"))))))
