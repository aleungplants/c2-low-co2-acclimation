// ===== ORANGE ROI AREA / PERIMETER / P:A RATIO =====

// 1. Get ROIs
n = roiManager("count");
if (n==0) exit("No ROIs found");

Stack.getDimensions(width, height, channels, slices, frames);
totalSlices = maxOf(slices, frames);

getPixelSize(unit, pw, ph);

print("\\Clear");
print("Processing stack with " + totalSlices + " slices");
print("Calibration: 1 pixel = " + pw + " " + unit);

// Arrays for orange ROIs per slice
orangeIndicesBySlice = newArray(totalSlices);
for (s=0;s<totalSlices;s++) orangeIndicesBySlice[s]="";

// 2. Classification
for (i=0;i<n;i++){
    roiManager("select", i);
    color = Roi.getStrokeColor();
    c = toLowerCase(color);
    if(indexOf(c,"ffa500")>=0 || indexOf(c,"ff8000")>=0 || indexOf(c,"orange")>=0){
        sliceIdx = getSliceNumber()-1;
        if(orangeIndicesBySlice[sliceIdx]=="") orangeIndicesBySlice[sliceIdx] = "" + i;
        else orangeIndicesBySlice[sliceIdx] = orangeIndicesBySlice[sliceIdx] + "," + i;
    }
}

// 3. Create table
title="Orange_ROI_Stats";
if(isOpen(title)){selectWindow(title); run("Close");}
Table.create(title);
rowCount=0;

totalArea=0;
totalPerimeter=0;

// 4. Process ROIs per slice
for(s=1;s<=totalSlices;s++){
    orangeStr = orangeIndicesBySlice[s-1];
    if(orangeStr=="") continue;
    indices = split(orangeStr,",");
    for(j=0;j<indices.length;j++){
        idx = parseInt(indices[j]);
        roiManager("select", idx);
        name = Roi.getName();

        run("Set Measurements...", "area perimeter decimal=3");
        roiManager("select", idx);
        List.setMeasurements();
        A = List.getValue("Area");
        P = List.getValue("Perim.");
        if(isNaN(A) || isNaN(P) || A<=0 || P<=0) continue;

        ratio = P/A;

        Table.set("Slice", rowCount, s);
        Table.set("ROI_Label", rowCount, name);
        Table.set("Area_" + unit + "^2", rowCount, A);
        Table.set("Perimeter_" + unit, rowCount, P);
        Table.set("P:A_Ratio", rowCount, ratio);
        rowCount++;

        totalArea += A;
        totalPerimeter += P;
    }
}

// 5. Single summary row
if(rowCount>0){
    Table.set("Slice", rowCount, 0); // 0 instead of slice number
    Table.set("ROI_Label", rowCount, "TOTAL");
    Table.set("Area_" + unit + "^2", rowCount, totalArea);
    Table.set("Perimeter_" + unit, rowCount, totalPerimeter);
    Table.set("P:A_Ratio", rowCount, totalPerimeter/totalArea);
    rowCount++;
}

// 6
