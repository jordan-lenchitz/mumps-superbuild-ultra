# 🚨 ultra fork 🚨

both professionally and recreationally i work with [MUMPS](https://en.wikipedia.org/wiki/MUMPS), a programming language from 1966 implemented as FOSS by [GT.M](https://sourceforge.net/projects/fis-gtm/). this is a fork of [MUMPS](https://mumps-solver.org/doc/userguide_5.8.2.pdf), the sparse direct solver from 1996 written in fortran. these two MUMPSes have nothing to do with each other, enjoy

## faq

what does each MUMPS stand for?
- MUMPS (**1966**) stands for "Massachusetts General Hospital Utility Multi-Programming System"
- MUMPS (**1996**) stands for "Multifrontal Massively Parallel Solver"

why does this fork exist?
- i thought the name was funny

will anything here ever be upstreamed?
- no, i sincerely hope not

what does `ULTRA_MODE` do?
- prints a banner at configure time reminding you which MUMPS you're building
- nothing to affect the actual `cmake` build in any way whatsoever
