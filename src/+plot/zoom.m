function zoom(hAxes, latitude, longitude, referenceDistanceKm)

    arclen = km2deg(referenceDistanceKm);
    
    [~, lim_long1] = reckon(latitude, longitude, arclen, -90);
    [~, lim_long2] = reckon(latitude, longitude, arclen,  90);    
    [lim_lat1, ~]  = reckon(latitude, longitude, arclen, 180);
    [lim_lat2, ~]  = reckon(latitude, longitude, arclen,   0);

    geolimits(hAxes, [lim_lat1, lim_lat2], [lim_long1, lim_long2]);

end