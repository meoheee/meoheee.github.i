---
title: "[Paper Review] USENIX'23 STYX"
categories:
  - Paper
tags:
  - Network
  - FPGA
---
# Styx: Exploiting SmartNIC Capability to Reduce Datacenter Memory Tax
<br>
>Due to copyright issues, I do not include `Figures` that are embedded in the paper :(
{: .prompt-warning }  

> This article is being edited
{: .prompt-danger }  
 
## Introduction
---

### Backgrounds

현대에는 메모리 중복 제거나 최적화 등이 다양한 커널 기능으로 나와 DRAM 용량을 더 효율적으로 쓰게 합니다. 그런데 마냥 좋아보이는 요게 사실은 CPU에서 상당한 간섭을 일으킨다고 하네요. 특히 자주 호출되지 않는 친구들이 메모리와 CPU에서 캐시를 잡아먹고 커널을 선점하며 반복적인 일을 하다보니 이를 운용해야하는 데이터센터 입장에서는 고비용 고지연의 단점을 얻게 됩니다.  

그래서 이 논문에서는 이런 데이터센터의 메모리 세금을 효율적으로 관리하기 위해 STYX를 만들었습니다. (SmarTnic to efficiently manage the datacenter memorY taX 의 줄임말 이라고 하는데 좀 구리다;;)
<br><br>
### What is STYX?

얘는 SmartNIC(이하 SNIC)의 두 가지를 활용한다고 합니다.  
1) RDMA로 커널 기능이 집중적으로 작동하려는 서버 메모리 영역을 SNIC 메모리로 복사하는 기능  
2) 커널 기능의 집중적인 작업을 비싼 서버 CPU에서 저렴한 SNIC CPU나 가속기로 오프로드하는 계산 기능  
그래서 1)을 통해 CPU 캐시 오염을 막고 2)를 통해 CPU 코어에 작업이 집중되는 걸 막는거죠!

아무튼 이걸 위해 메모리 최적화 리눅스 커널 기능을 다시 구현했다고 합니다.  
1) `ksm` : 커널 동일 페이지 병합  
2) `zswap` : 스왑 페이지를 위한 압축 캐시  
<br><br>
## Summary
---

### Backgrounds

위에서 말한 `ksm`과 `zswap`이 뭔지 먼저 알아보고 가도록 하죠!  

<br><br>

<br><br>
## Review
---


<br><br>
## Strength & Weakness
---


<br><br>

Thanks!!