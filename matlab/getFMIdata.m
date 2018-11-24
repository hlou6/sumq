

% general settings
apikey = 'ENTER API KEY HERE';
datapath = 'data/data_%s_%d.xml'; % string = fmisid, integer = batch number

% weather station identifier
% 101004: helsinki kumpula
% 101247: lappeenranta lepola
% 100921: k�kar bogsk�r
% 101887: kuusamo kiutak�ng�s
% 101315: j�ms� lentoasema
% 101339: jyv�skyl� lentoasema
% 102016: kilpisj�rvi kyl�keskus
% 101154: h�meenlinna lammi pappila
% 101773: kuhmo kalliojoki
% 100908: parainen ut�
fmisid = '100908'; 

% dataset identifiers
dataset = 'fmi::observations::weather::multipointcoverage';
date_begin = 'January 01, 2010 00:00:00';
date_end = 'January 01, 2018 00:00:00';


[ nbatches ] = downloadFMIdata( apikey, dataset, fmisid, datapath, date_begin, date_end );
[ alldata, time ] = parseXMLfiles( nbatches, dataset, datapath, fmisid );
[ weather ] = extractWeatherData( nbatches, alldata, time, dataset );