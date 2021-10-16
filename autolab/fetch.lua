student_cookie = "browser.timezone=America/Los_Angeles; _autolab3_session=Z05Vdy8xT2RNWVRJWWNDVXVnRVVOYnpvcndlcmRjRVhvZzU2YlhEaHZmQlkrZEthQlh4KysxL2hUay9DajVCeVpMV2tEa3kzK1hZd0p5RVJlL1NsdlBna200Skh2M3dxZzF6cWt5QTRFODdRNDVCbWNZTXN4clJaS2kyOXJoYmhHVVhJUmU0b3hweVR6STR4TlZZTVBjVkk3RWpINDZ3SUJ0cnBBcDVPUVl1WVdjcFg5ZElVQUE5bTc2NkFhSUlCWmxJNVliRWpMTXNJMnpBNkhKV3dUK05ZSWZYV2FTazdZSHFnSDc0eFYyall0RVNkM0U1S3RkVEZwZmJRbkZtVC0tME9ndDdOZnY5L2ppWEd2dW9PSVB0QT09--ff52958aab49f35ac1743a6d689cf29af10142e8"
instructor_cookie = "browser.timezone=America/Los_Angeles; _autolab3_session=SGIrSWt5NkRaWlhQVVJlTi9MeHpLVTAxT0o0N2JLRDE5TnkvM0RqWFJMTXdFZlo5Z1RHazV4YnloMzBOYzZITXFxZmsrQnNJRGFkWkFRbWxJbTBkRzJwVnppeW5UNHFERk8yTjFDTFp0QmgxS2NIY1lERmpadjBncHAveXUrbEpqWVI0eWVvdkNxMFFCajlDa2crbWhyTHpZWHhsT25PSFA1UmVkcUpuaGZTYkhaNU90QUx6N0lObkNTVkhPZWpCT1hxWWNJSytFZjRaRHNiNy9ZR1RtOG56Q1NBUjJpQjZGakI0cjlvSlNscDVacWRLdGU2dE1RUEJsdGRWdnQ3Mi0tTis4MGxhdE5yS2p0OE5BaHBmbTVGdz09--25780005e9753dead742abbce8893950d8e19524"

wrk.headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -- Default
wrk.headers["Cookie"] = student_cookie

counter = 0
r = {}


init = function(args)
   r[1] = wrk.format(nil, "/")
   r[2] = wrk.format(nil, "/courses/Course0/assessments")

   json_headers = {}
   json_headers["Cookie"] = student_cookie
   json_headers["Accept"] = "application/json, text/javascript"
   json_headers["X-Requested-With"] = "XMLHttpRequest"
   r[3] = wrk.format(nil, "/courses/Course0/metrics/get_num_pending_instances", json_headers)

   r[4] = wrk.format(nil, "/courses/Course0/assessments/quiz4")
   r[5] = wrk.format(nil, "/courses/Course0/assessments/quiz4/submissions/26000028/download")
   r[6] = wrk.format(nil, "/courses/Course0/assessments/quiz4/viewGradesheet", {Accept=wrk.headers["Accept"], Cookie=instructor_cookie})
end

request = function()
   counter = (counter + 1) % 6
   if counter == 0 then counter = 6 end
   return r[counter]
end

