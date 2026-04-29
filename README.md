README

\- ECE 3971, 4971, 4972/4973 2026 Cohort

\- Cell Imaging 2026 Team

\- Written 4/27/2026 at 4:05pm by Demetrius Schank



*Note: this document was written for navigating the Villanova OneDrive directory that is currently accessible. Instructions for other host platforms (i.e. GitHub) may differ, but should still have similar if not identical directory organization.*







**\*\*To download and run the necessary MATLAB code, navigate to the following directories.\*\***



Most recent MATLAB code for this project:

&#x09;"ECE Capstone Cohort 2026 > Cell Imaging > Documents > Cell Imaging > MATLAB Scripts > USEME\_measure\_cell\_deformation\_v3.m"





The main video file used:

&#x09;"ECE Capstone Cohort 2026 > Cell Imaging > Documents > Cell Imaging > Fall 2025 > RBC Movies > c3lc50427a.mwmv"



*Note: other videos listed in this directory are derivatives from this main .wmv file, excluding "...esi\_movie2.avi" and "...esi\_movie3.avi".*



Links to each video’s source journal articles can be found in this spreadsheet:

&#x09;"ECE Capstone Cohort 2026 > Cell Imaging > Documents > Cell Imaging > Fall 2025 > RBC Movies > Legend - Video PDF Sources.xlsx"



PDF backups (Spring/Fall 2025 versions) for these journal articles can be found in:

&#x09;"ECE Capstone Cohort 2026 > Cell Imaging > Documents > Cell Imaging > Fall 2025 > RBC Movies > Article PDFs"













**\*\*Instructions for Running the MATLAB Cell Imaging System:\*\***



To properly execute the cell deformation analysis program, follow the steps below in order.



1\. Open MathWorks® MATLAB on your system.



2\. Navigate to the project directory and open USEME\_measure\_cell\_deformation\_v3.m



3\. Click Run to begin execution of the program.



4\. When prompted, upload a cell imaging video file from the RBC Movies directory.



5\. After video upload, follow any optional prompts:

\- Remove duplicate frames before analysis? Select YES or NO depending on preference

\- Enter calibration scale if known or estimated

\- Enter frame acquisition rate if known or estimated



6\. Select two frames from the frame browser:

\- Frame A (initial condition)

\- Frame B (comparison condition)



7\. For each frame:

\- Draw a Region of Interest (ROI) around the cells

\- Confirm or redraw if necessary



8\. Allow the program to process the selected frames.



9\. Review results displayed in the MATLAB Command Window:

\- Cell boundary detection output

\- X-axis deformation

\- Y-axis deformation

\- Aspect ratio change if applicable

\- Overall deformation metrics



10\. The program is complete when results are fully displayed in the Command Window with no execution errors.



&#x09;*Notes:*

&#x09;	*- MATLAB must remain the only active execution environment during runtime.*

&#x09;	*- Some video formats may require OS-level codec support depending on system configuration.*

&#x09;	*- All outputs are based on 2D cell boundary detection and ROI-based analysis.*

&#x09;	*- Required MATLAB toolboxes and additional open-source dependencies may need to be*

&#x09;	*installed if not already present (refer to Parts and Components in Final Report).*

"# villanova-ee-cpe-cell-imaging-2026" 
