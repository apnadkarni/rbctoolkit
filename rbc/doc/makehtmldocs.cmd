@echo INSTRUCTIONS:
@echo.
@echo On a Unix system, run the following commands.
@echo   groff -mandoc -Thtml barchart.n etc.
@echo Then edit the files to get rid of the horizontal __ lines
@echo Just before the Name and at the end of SYNOPSIS.

@rem the commands below produce badly styled output, at least with
@rem the mandoc program available for Windows, thus the above instruction.
@exit /b

mandoc -Thtml -Ostyle=rbc.css barchart.n > barchart.html
mandoc -Thtml -Ostyle=rbc.css graph.n > graph.html
mandoc -Thtml -Ostyle=rbc.css spline.n > spline.html
mandoc -Thtml -Ostyle=rbc.css stripchart.n > stripchart.html
mandoc -Thtml -Ostyle=rbc.css vector.n > vector.html
mandoc -Thtml -Ostyle=rbc.css winop.n > winop.html
