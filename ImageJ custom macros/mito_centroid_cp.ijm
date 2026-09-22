// Get all ROIs from ROI Manager
n = roiManager("count");
if (n == 0) {
    exit("No ROIs found in ROI Manager");
}

// Get image stack info
Stack.getDimensions(width, height, channels, slices, frames);
totalSlices = maxOf(slices, frames);

print("\\Clear");
print("Processing stack with " + totalSlices + " slices");

// Arrays to store ROIs organized by slice
chloroBySlice = newArray(totalSlices);
mitoBySlice = newArray(totalSlices);

// Initialize arrays for each slice
for (s = 0; s < totalSlices; s++) {
    chloroBySlice[s] = "";
    mitoBySlice[s] = "";
}

// Organize ROIs by slice and color
for (i = 0; i < n; i++) {
    roiManager("select", i);
    
    // Get ROI name and extract ROI number before hyphen
    roiName = Roi.getName();
    roiNum = i; // default to index
    if (indexOf(roiName, "-") >= 0) {
        parts = split(roiName, "-");
        roiNum = parseInt(parts[0]);
    }
    
    // Get current slice number from the stack
    currentSlice = getSliceNumber();
    sliceIdx = currentSlice - 1;
    
    // Get color property
    color = Roi.getStrokeColor();
    colorName = toLowerCase(color);
    
    // Add to appropriate array
    if (indexOf(colorName, "green") >= 0) {
        if (chloroBySlice[sliceIdx] == "") {
            chloroBySlice[sliceIdx] = "" + roiNum;
        } else {
            chloroBySlice[sliceIdx] = chloroBySlice[sliceIdx] + "," + roiNum;
        }
    } else if (indexOf(colorName, "red") >= 0) {
        if (mitoBySlice[sliceIdx] == "") {
            mitoBySlice[sliceIdx] = "" + roiNum;
        } else {
            mitoBySlice[sliceIdx] = mitoBySlice[sliceIdx] + "," + roiNum;
        }
    }
}

// Create results table
title = "Mito-Chloroplast Distances";
if (isOpen(title)) {
    selectWindow(title);
    run("Close");
}
Table.create(title);

rowCount = 0;

// Process each slice
for (s = 1; s <= totalSlices; s++) {
    // Get chloroplast and mitochondria indices for this slice
    chloroStr = chloroBySlice[s-1];
    mitoStr = mitoBySlice[s-1];
    
    if (chloroStr == "" || mitoStr == "") {
        print("Slice " + s + ": No matching ROIs");
        continue;
    }
    
    chloroIndices = split(chloroStr, ",");
    mitoIndices = split(mitoStr, ",");
    
    print("Slice " + s + ": " + mitoIndices.length + " mitochondria, " + chloroIndices.length + " chloroplasts");
    
    // For each mitochondrion on this slice
    for (m = 0; m < mitoIndices.length; m++) {
        mitoIdx = parseInt(mitoIndices[m]);
        roiManager("select", mitoIdx);
        
        // Get mitochondrion centroid
        List.setMeasurements();
        mitoCentroidX = List.getValue("X");
        mitoCentroidY = List.getValue("Y");
        
        minDist = 999999;
        nearestChloroIdx = -1;
        
        // Check distance to each chloroplast on the SAME slice
        for (c = 0; c < chloroIndices.length; c++) {
            chloroIdx = parseInt(chloroIndices[c]);
            roiManager("select", chloroIdx);
            
            // Get chloroplast centroid
            List.setMeasurements();
            chloroCentroidX = List.getValue("X");
            chloroCentroidY = List.getValue("Y");
            
            // Calculate Euclidean distance
            dx = mitoCentroidX - chloroCentroidX;
            dy = mitoCentroidY - chloroCentroidY;
            dist = sqrt(dx*dx + dy*dy);
            
            if (dist < minDist) {
                minDist = dist;
                nearestChloroIdx = chloroIdx;
            }
        }
        
        // Add to results table
        Table.set("Slice", rowCount, s);
        Table.set("Mitochondrion_ROI", rowCount, mitoIdx);
        Table.set("Nearest_Chloroplast_ROI", rowCount, nearestChloroIdx);
        Table.set("Distance_pixels", rowCount, minDist);
        rowCount++;
    }
}

Table.update(title);
print("\\Update:Analysis complete! " + rowCount + " mitochondria analyzed across " + totalSlices + " slices.");

// Show all ROIs with labels
roiManager("Show All with labels");
roiManager("deselect");