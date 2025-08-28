function zoom(hAxes, Latitude, Longitude, ReferenceDistance_km)

    arclen         = km2deg(ReferenceDistance_km);
    [~, lim_long1] = reckon(Latitude, Longitude, arclen, -90);
    [~, lim_long2] = reckon(Latitude, Longitude, arclen,  90);    
    [lim_lat1, ~]  = reckon(Latitude, Longitude, arclen, 180);
    [lim_lat2, ~]  = reckon(Latitude, Longitude, arclen,   0);

    geolimits(hAxes, [lim_lat1, lim_lat2], [lim_long1, lim_long2]);

end