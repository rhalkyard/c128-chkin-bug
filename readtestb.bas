10 rem test case for chkin bug
20 d = peek(186)
20 open 2,d,2,"file1"
30 gosub 2000
40 open 3,d,3,"file2"
50 gosub 3000
60 gosub 2000
70 gosub 3000
80 if st = 0 then 70
90 close 3
100 gosub 2000
110 if st = 0 then 100
120 close 2
130 end

2000 get#2, c$
2010 print c$;
2020 if (st = 0) and (c$ <> chr$(13)) then 2000
2030 return

3000 get#3, c$
3010 print c$;
3020 if (st = 0) and (c$ <> chr$(13)) then 3000
3030 return
