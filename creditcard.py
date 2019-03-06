import re

c = input()
b=0
pattern1 = r"[4-6]{1}[0-9]{3}\-[0-9]{4}\-[0-9]{4}\-[0-9]{4}|[4-6]{1}[0-9]{15}"
m=re.match(pattern1,c)
pattern2 = r'(\d)\1{3}'
n=re.search(pattern2,c)
while b<1 :
  if n:
    print("invalid")
    break
  else:
   print("")
  if m:
    print("valid")
  else:
    print("invalid")
  b+=1  

