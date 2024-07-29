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

1) `ksm` : 리눅스의 메모리 중복 제거 기능입니다. 여러 VM 간 동일한 내용을 가진 페이지를 공유해서 주어진 물리적 메모리 용량 내에서 consolidate(뭔 뜻인지 모르겠ㅠㅠ) 한다고 합니다.  
2) `zswap` : 리눅스 Swap Daemon(kswapd)을 위한 압축 백엔드 역할을 합니다. Synchronous Direct Path와 Asynchrounous Background Path로 나뉜다고 하네요.  
	- 동기식 경로는 메모리 부족으로 페이지 할당에 실패했을 때 씁니다.  
	- 비동기식 경로는 쓸 수 있는 메모리 여유 공간이 `page_low` 마크보다 아래로 떨어졌을 때 씁니다.  
자세한 설명은 Backgrouds 직접 읽어보세요! (zswap 설명이 꽤 김)  
그리고 이 글을 읽을 정도라면 SNIC과 RDMA가 뭔진 구글링 좀만 해보면 다 아실테니 넘어갈게요!  

<br><br>
### Problems

저자는 `Figure 2`를 통해 ksm과 zswap을 배포하는 데에 필요한 비용에 대해 이야기하며 이 커널 기능들이 애플리케이션 성능에 미치는 영향에 대해 이야기하고 있습니다.  

`Figure 2`에 따르면 `zswap`이 CPU 사이클, LLC 미스율, Redis 응답 지연 시간 부분에서 모두 증가했다고 합니다. 그리고 그림에는 없지만 ksm도 마찬가지라고 합니다. 아래는 원인입니다.  

1) `ksm` : 병합할 페이지를 인식하려면 32비트 체크섬을 계산하는데, 이 때 발생하는 수많은 산술 작업이 문제라고 하네요
2) `zswap` : 얘가 호출되면 압축과 압축 해제 작업을 하는데 이것 역시 계산이 많이 필요하다고 합니다.
<br><br>
## STYX Framework

두 메모리 최적화용 커널 기능이 Control/Data Plane으로 분할될 수 있다고 합니다. 이를 기반으로 STYX를 설계했다고 하네요. CPU와 메모리에 집중되는 작업은 Data Plane에서 처리하게 하고 SNIC의 CPU가 연산 처리를 한다고 합니다.  

`Figure 3`에 Workflow가 있습니다.  
1) Setup - 명령어 호출 시 작동할 메모리 영역을 결정하고  
2) Submission - 해당 영역을 서버 CPU의 캐시에 복사하고  
3) Remote Execution - 해당 영역에서 작업한 후  
4) Completion - 결과에 따라 다음 단계를 결정  
1)과 4)는 Control Plane, 2)와 3)은 Data Plane에 할당됩니다.  
다시 말하면, 2)와 3)의 Data Plane 연산을 SNIC의 CPU에서 처리하게 하니 서버 CPU가 편해지는 것이죠! 그리고 메모리 접근은 RDMA를 통해 서버 메모리에서 SNIC의 메모리로 가져오며 이루어진다고 하네요.  

WorkFlow에 대해 더 자세히 이야기 해보겠습니다. 총 4가지 단계로 구성된다고 하네요.
1) Setup
	- SNIC으로 오프로드할 기능을 결정합니다.
	- 서버와 SNIC 간 RDMA 연결을 설정합니다.
2) Submission
	- 서버의 STYX가 메모리 영역의 시작 주소와 길이를 업데이트 합니다.
	- 서버의 STYX가 RDMA 요청을 보내 서버의 메모리에서 SNIC의 메모리로 복사할 수 있도록 합니다.
	- STYX는 RDMA 전송 결과를 서버로 다시 보낼 때까지 커널 feature 실행을 중단합니다. (다른 프로세스가 쓰도록 서버 다른 CPU  코어 양보)
	- 단측 RDMA를 쓸 경우 SNIC의 STYX가 RDMA 읽기를 써서 메모리 영역을 계속 폴링합니다. (대신 이러면 PCIe bandwidth와 SNIC CPU의 사이클을 잡아먹겠죠)
3) Remote Execution
	- 서버에서 RDMA 전송을 받은 후 SNIC이 RDMA 수신 요청에 따라 RDMA 메모리 복사를 시작합니다.
	- SNIC의 STYX가 작업할 스레드를 생성합니다.
4) Completion
	- SNIC의 STYX가 서버의 STYX에게 결과를 보내기 위해 RDMA 전송 요청을 올리고, 서버가 받으면 커널 기능을 재개합니다. 그리고 서버 메모리에서 결과를 읽습니다.
	- SNIC의 STYX는 다음 RDMA 전송을 받기 전까지 대기합니다.

<br><br>
## Review
---


<br><br>
## Strength & Weakness
---


<br><br>

Thanks!!