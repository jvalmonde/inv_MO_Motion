
select *,Replace(replace(replace(Address1, ' Apartments ', ' # '), ' Apt. ', ' # '), ' No ', ' # ')  from pdb_walkandwin..move_to_alt_invite_temp 

declare @addr varchar(256), @str varchar(100), @city varchar(100), @num varchar(20), 
		@apt varchar(20), @dir varchar(20), @tp varchar(20), @state varchar(2), 
		@zip varchar(5), @lat decimal(9,5), @lon decimal(9,5), 
		@wt int, @i int,	@j int, @h int, --included j  and h 
		@fraddr int, @frlon decimal(9,5), @frlat decimal(9,5), 
		@toaddr int, @tolon decimal(9,5), @tolat decimal(9,5), 
		@ratio decimal(9,5), @str1 varchar(128), @str2 varchar(128)

	select @str = replace(replace(replace(@addr, '.', ' '), '&', '/'), '-', ' '),						--modifed 
		@city='', @num='', @apt='', @dir='', @tp='', @state='', @zip='',
		@lat=0, @lon=0, @wt = -1
	set @str = replace(replace(replace(@str, '1/2', ' '), '1/4', ' '), '3/4', ' ')
	set @str = Replace(replace(replace(@str, ' Apt ', ' # '), ' Unit ', ' # '), ' No ', ' # ')
	set @str = Replace(replace(replace(@str, ' Apartments ', ' # '), ' Apt. ', ' # '), ' No ', ' # ')	--added
	set @str = Replace(Replace(replace(@str, ' Apartment ', ' '), ' Suite ', ' # '), ' ste ', ' # ')
	set @str = Replace(@str,' SPC ', ' # ')
	set @str = ltrim(rtrim(replace(@str, '  ', ' ')))
	set @str = replace(@str, ', #', ' #')

	set @i = charindex(',', @str)
	if (@i > 0) 
		select  @city = replace(ltrim(substring(@str, @i+1, 999)), ',', ' '),
				@str = replace(rtrim(substring(@str, 1, @i-1)), ',', ' ')

	set @i = charindex(' ', @str)
	if (@i > 0 and isnumeric(substring(@str, 1, @i))=1) 
		select  @num = rtrim(substring(@str, 1, @i-1)), 
				@str = ltrim(substring(@str, @i+1, 999))

	set @i = charindex(' ', @str)
	if (@i > 0 and substring(@str, 1, @i-1) IN ('N','No','North','South','S','West','W','East','E','NE','SE','NW','SW'))
		select  @dir = rtrim(substring(@str, 1, 1)), 
				@str = ltrim(substring(@str, @i+1, 999))	
		
	set @i = charindex('#', @str)											-- modified from here 
	set @j = CHARINDEX(' ', @str)
	if (@i = 1)and (@j > @i) and isnumeric(substring(@str, @i+1, @j-1-@i)) = 1 
			select  @num = substring(@str, @i+1, @j-1-@i)	
				set @h = charindex(' ', @city)
					if (@h > 0 and substring(@city, 1, @h-1)in ('N','No','North','South','S','West','W','East','E','NE','SE','NW','SW'))
						select	@dir = substring(@city, 1, @h-1),
								@city = substring(@city, @h+1, 999)			--modified until here 
			--select @num = rtrim(substring(@num, @i-1, 999)),
			--	@str = RTRIM(substring(@str, @i+1, 999)) 					
			
	--set @i = charindex('#', @str)
	--if (@i > 0) 
	--	select @apt = ltrim(substring(@str, @i+1, 999)),
	--	@str = rtrim(substring(@str, 1, @i-1))

	set @i = len(@str) - charindex(' ', reverse(@str))
	if (@i > 0 and @i < len(@str)
	and substring(@str, @i+2, 999) IN ('N','No','North','South','So', 'S','West','W','East','E','NE','SE','NW','SW'
		, 'Northeast', 'North-East', 'Southeast', 'South-East', 'Northwest', 'North-West', 'Southwest', 'South-West')) 
		select  @dir = substring(@str, @i+2, 1),
				@str = rtrim(substring(@str, 1, @i))

	set @i = len(@str) - charindex(' ', reverse(@str))
	if (@i > 0 and @i < len(@str)) begin
		set @str1 = ltrim(substring(@str, @i+1, 999))
		set @str1 = case @str1
				when 'Alley'		then 'Aly'	
				when 'Allee'		then 'Aly'	
				when 'Ally'			then 'Aly'	
				when 'Aly'			then 'Aly'
				when 'Anex'			then 'Anx'	
				when 'Annex'		then 'Anx'	
				when 'Annx'			then 'Anx'	
				when 'Anx'			then 'Anx'
				when 'Arc'			then 'Arc'  
				when 'Arcade'		then 'Arc'
				when 'Avenue'		then 'Ave'	
				when 'Av'			then 'Ave'	
				when 'Ave'			then 'Ave'
				when 'Ave.'			then 'Ave'	
				when 'Aven'			then 'Ave'	
				when 'Avenu'		then 'Ave'	
				when 'Aveune'		then 'Ave'
				when 'Avn'			then 'Ave'	
				when 'Avnue'		then 'Ave' 
				when 'Bayoo'		then 'Byu'	
				when 'Bayou'		then 'Byu'
				when 'Bch'			then 'Bch'	
				when 'Beach'		then 'Bch'
				when 'Bend'			then 'Bnd'	
				when 'Bnd'			then 'Bnd'
				when 'Blf'			then 'Blf'	
				when 'Bluf'			then 'Blf'	
				when 'Bluff'		then 'Blf'
				when 'Bluffs'		then 'Blfs' 
				when 'Bot'			then 'Btm'	
				when 'Btm'			then 'Btm'	
				when 'Bottm'		then 'Btm'	
				when 'Bottom'		then 'Btm'
				when 'Blvd'			then 'Blvd'
				when 'Boul'			then 'Blvd'
				when 'Boulevard'	then 'Blvd'
				when 'Boulv'		then 'Blvd'
				when 'Br'			then 'Br'	
				when 'Brnch'		then 'Br'	
				when 'Branch'		then 'Br'
				when 'Brdge'		then 'Brg'	
				when 'Brg'			then 'Brg'	
				when 'Bridge'		then 'Brg'
				when 'Brk'			then 'Brk'	
				when 'Brook'		then 'Brk'	
				when 'Brooks'		then 'Brks'
				when 'Burg'			then 'Bg'
				when 'Burgs'		then 'Bgs'
				when 'Byp'			then 'Byp'	
				when 'Bypa'			then 'Byp'	
				when 'Bypas'		then 'Byp'		
				when 'Bypass'		then 'Byp'	
				when 'Byps'			then 'Byp'
				when 'Camp'			then 'Cp'	
				when 'Cp'			then 'Cp'	
				when 'Cmp'			then 'Cp'
				when 'Canyn'		then 'Cyn'	
				when 'Canyon'		then 'Cyn'	
				when 'Cnyn'			then 'Cyn'
				when 'Cape'			then 'Cpe'	
				when 'Cpe'			then 'Cpe'
				when 'Causeway'		then 'Cswy'	
				when 'Causwa'		then 'Cswy'	
				when 'Cswy'			then 'Cswy'
				when 'Cen'			then 'Ctr'	
				when 'Cent'			then 'Ctr'	
				when 'Center'		then 'Ctr'	
				when 'Centr'		then 'Ctr'	
				when 'Centre'		then 'Ctr'	
				when 'Cnter'		then 'Ctr'	
				when 'Cntr'			then 'Ctr'	
				when 'Ctr'			then 'Ctr'
				when 'Centers'		then 'Ctrs'
				when 'Cir'			then 'Cir'	
				when 'Circ'			then 'Circ'	
				when 'Circl'		then 'Cir'	
				when 'Circle'		then 'Cir'	
				when 'Crcl'			then 'Cir'	
				when 'Crcle'		then 'Cir'
				when 'Circles'		then 'Cirs'
				when 'Clf'			then 'Clf'	
				when 'Cliff'		then 'Clf'
				when 'Clfs'			then 'Clfs'	
				when 'Cliffs'		then 'Clfs'
				when 'Clb'			then 'Clb'	
				when 'Club'			then 'Clb'
				when 'Common'		then 'Cmn'
				when 'Commons'		then 'Cmns'
				when 'Cor'			then 'Cor'	
				when 'Corner'		then 'Cor'
				when 'Cors'			then 'Cors'	
				when 'Corners'		then 'Cors'
				when 'Course'		then 'Crse'	
				when 'Crse'			then 'Crse'
				when 'Court'		then 'Ct'	
				when 'Ct'			then 'Ct'
				when 'Courts'		then 'Cts'	
				when 'Cts'			then 'Cts'
				when 'Cove'			then 'Cv'	
				when 'Cv'			then 'Cv'
				when 'Coves'		then 'Cvs'
				when 'Creek'		then 'Crk'	
				when 'Crk'			then 'Crk'
				when 'Crescent'		then 'Cres'	
				when 'Cres'			then 'Cres'	
				when 'Crsent'		then 'Cres'	
				when 'Crsnt'		then 'Cres'
				when 'Crest'		then 'Crst'
				when 'Crossing'		then 'Xing'	
				when 'Crssng'		then 'Xing'	
				when 'Xing'			then 'Xing'
				when 'Crossroad'	then 'Xrd'
				when 'Crossroads'	then 'Xrds'
				when 'Curve'		then 'Curv'
				when 'Dale'			then 'Dl'	
				when 'Dl'			then 'Dl'
				when 'Dam'			then 'Dm'	
				when 'Dm'			then 'Dm'
				when 'Div'			then 'Dv'	
				when 'Divide'		then 'Dv'	
				when 'Dv'			then 'Dv'	
				when 'Dvd'			then 'Dv'
				when 'Dr'			then 'Dr'
				when 'Dr.'			then 'Dr'	
				when 'Driv'			then 'Dr'	
				when 'Drive'		then 'Dr'
				when 'Drvie'		then 'Dr'	
				when 'Drv'			then 'Dr'
				when 'Drv.'			then 'Dr'
				when 'Drives'		then 'Drs'
				when 'Est'			then 'Est'	
				when 'Estate'		then 'Est'
				when 'Estates'		then 'Ests'	
				when 'Ests'			then 'Ests'
				when 'Exp'			then 'Expy'	
				when 'Expr'			then 'Expy'	
				when 'Express'		then 'Expy'	
				when 'Expressway'	then 'Expy'	
				when 'Expw'			then 'Expy'	
				when 'Expy'			then 'Expy'
				when 'Ext'			then 'Ext'	
				when 'Extension'	then 'Ext'	
				when 'Extn'			then 'Extn'	
				when 'Extnsn'		then 'Extn'
				when 'Exts'			then 'Exts'
				when 'Fall'			then 'Fall'
				when 'Falls'		then 'Fls'	
				when 'Fls'			then 'Fls'
				when 'Ferry'		then 'Fry'	
				when 'Frry'			then 'Fry'	
				when 'Fry'			then 'Fry'
				when 'Field'		then 'Fld'	
				when 'Fld'			then 'Fld'
				when 'Fields'		then 'Flds'	
				when 'Flds'			then 'Flds'
				when 'Flat'			then 'Flt'	
				when 'Flt'			then 'Flt'
				when 'Flats'		then 'Flts'	
				when 'Flts'			then 'Flts'
				when 'Ford'			then 'Frd'	
				when 'Frd'			then 'Frd'
				when 'Fords'		then 'Frds'
				when 'Forest'		then 'Frst'	
				when 'Forests'		then 'Frst'	
				when 'Frst'			then 'Frst'
				when 'Forg'			then 'Frg'	
				when 'Forge'		then 'Frg'	
				when 'Frg'			then 'Frg'
				when 'Forges'		then 'Frgs'
				when 'Fork'			then 'Frk'	
				when 'Frk'			then 'Frk'
				when 'Forks'		then 'Frks'	
				when 'Frks'			then 'Frks'
				when 'Fort'			then 'Ft'	
				when 'Frt'			then 'Ft'	
				when 'Ft'			then 'Ft'
				when 'Freeway'		then 'Fwy'	
				when 'Freewy'		then 'Fwy'	
				when 'Frway'		then 'Fwy'	
				when 'Frwy'			then 'Fwy'	
				when 'Fwy'			then 'Fwy'
				when 'Garden'		then 'Gdn'	
				when 'Gardn'		then 'Gdn'	
				when 'Grden'		then 'Gdn'	
				when 'Grdn'			then 'Gdn'
				when 'Gardens'		then 'Gdns'	
				when 'Gdns'			then 'Gdns'	
				when 'Grdns'		then 'Gdns'
				when 'Gateway'		then 'Gtwy'	
				when 'Gatewy'		then 'Gtwy'	
				when 'Gatway'		then 'Gtwy'	
				when 'Gtway'		then 'Gtwy'	
				when 'Gtwy'			then 'Gtwy'
				when 'Glen'			then 'Gln'	
				when 'Gln'			then 'Gln'
				when 'Glens'		then 'Glns'
				when 'Green'		then 'Grn'	
				when 'Grn'			then 'Grn'
				when 'Greens'		then 'Grns'
				when 'Grov'			then 'Grv'	
				when 'Grove'		then 'Grv'	
				when 'Grv'			then 'Grv'
				when 'Groves'		then 'Grvs'
				when 'Harb'			then 'Hbr'	
				when 'Harbor'		then 'Hbr'	
				when 'Harbr'		then 'Hbr'	
				when 'Hbr'			then 'Hbr'	
				when 'Hrbor'		then 'Hbr'
				when 'Harbors'		then 'Hbrs'
				when 'Haven'		then 'Hvn'	
				when 'Hvn'			then 'Hvn'
				when 'Ht'			then 'Hts'	
				when 'Hts'			then 'Hts'	
				when 'Heights'		then 'Hts'	
				when 'Height'		then 'Hts'
				when 'Highway'		then 'Hwy'	
				when 'Highwy'		then 'Hwy'	
				when 'Hiway'		then 'Hwy'	
				when 'Hiwy'			then 'Hwy'	
				when 'Hway'			then 'Hwy'	
				when 'Hwy'			then 'Hwy'
				when 'Hill'			then 'Hl'	
				when 'Hl'			then 'Hl'
				when 'Hills'		then 'Hls'	
				when 'Hls'			then 'Hls'
				when 'Hllw'			then 'Holw'	
				when 'Hollow'		then 'Holw'	
				when 'Hollows'		then 'Holw'	
				when 'Holw'			then 'Holw'	
				when 'Holws'		then 'Holw'
				when 'Inlt'			then 'Inlt'
				when 'Is'			then 'Is'	
				when 'Island'		then 'Is'	
				when 'Islnd'		then 'Is'
				when 'Islands'		then 'Iss'	
				when 'Islnds'		then 'Iss'	
				when 'Iss'			then 'Is'
				when 'Isle'			then 'Ilse'	
				when 'Isles'		then 'Isles'
				when 'Jct'			then 'Jct'	
				when 'Jction'		then 'Jct'	
				when 'Jctn'			then 'Jct'	
				when 'Junction'		then 'Jct'	
				when 'Junctn'		then 'Jct'	
				when 'Juncton'		then 'Jct'
				when 'Jctns'		then 'Jct'	
				when 'Jcts'			then 'Jcts'	
				when 'Junctions'	then 'Jcts'
				when 'Key'			then 'Ky'
				when 'Ky'			then 'Ly'
				when 'Keys'			then 'Kys'
				when 'Kys'			then 'Kys'
				when 'Knoll'		then 'Knl'
				when 'Knol'			then 'Knl'
				when 'Knl'			then 'Knl'
				when 'Knls'			then 'Knls'
				when 'Knolls'		then 'Knls'
				when 'Lk'			then 'Lk'
				when 'Lake'			then 'Lk'
				when 'Lks'			then 'Lks'
				when 'Lakes'		then 'Lks'
				when 'Land'			then 'Land'
				when 'Landing'		then 'Lndg'
				when 'Lndg'			then 'Lndg'
				when 'Lndng'		then 'Lndg'
				when 'Lane'			then 'Ln'
				when 'Ln'			then 'Ln'
				when 'Lgt'			then 'Lgt'
				when 'Light'		then 'Lgt'
				when 'Lights'		then 'Lgts'
				when 'Loaf'			then 'Lf'
				when 'Loaf'			then 'Lf'
				when 'Lock'			then 'Lck'
				when 'Lck'			then 'Lck'
				when 'Locks'		then 'Lcks'
				when 'Lcks'			then 'Lcks'
				when 'Ldg'			then 'Ldg'
				when 'Ldge'			then 'Ldg'
				when 'Lodg'			then 'Ldg'
				when 'Lodge'		then 'Ldg'
				when 'Loop'			then 'Loop'
				when 'Loops'		then 'Loop'
				when 'Mall'			then 'Mall'
				when 'Mnr'			then 'Mnr'
				when 'Manor'		then 'Mnr'
				when 'Manors'		then 'Mnrs'
				when 'Mnrs'			then 'Mnrs'
				when 'Meadow'		then 'Mdw'
				when 'Mdw'			then 'Mdws'
				when 'Mdws'			then 'Mdws'
				when 'Meadows'		then 'Mdws'
				when 'Medows'		then 'Mdws'
				when 'Mews'			then 'Mews'
				when 'Mill'			then 'Ml'
				when 'Mills'		then 'Mls'
				when 'Missn'		then 'Msn'
				when 'Mssn'			then 'Msn'
				when 'Motorway'		then 'Mtwy'
				when 'Mntain'		then 'Mtn'
				when 'Mntn'			then 'Mtn'
				when 'Mountain'		then 'Mtn'
				when 'Mountin'		then 'Mtn'
				when 'Mtin'			then 'Mtn'
				when 'Mtn'			then 'Mtn'
				when 'Mnts'			then 'Mtns'
				when 'Mountains'	then 'Mtns'
				when 'Nck'			then 'Nck'
				when 'Neck'			then 'Nck'
				when 'Orch'			then 'Orch'
				when 'Orchard'		then 'Orch'
				when 'Orchrd'		then 'Orch'
				when 'Oval'			then 'Oval'
				when 'Ovl'			then 'Oval'
				when 'Overpass'		then 'Opas'
				when 'Park'			then 'Park'
				when 'Prk'			then 'Park'
				when 'Parks'		then 'Park'
				when 'Parkway'		then 'Pkwy'
				when 'Parkwy'		then 'Pkwy'
				when 'Pkway'		then 'Pkwy'
				when 'Pkwy'			then 'Pkwy'
				when 'Pky'			then 'Pkwy'
				when 'Parkways'		then 'Pkwy'
				when 'Pkwys'		then 'Pkwy'
				when 'Pass'			then 'Pass'
				when 'Passage'		then 'Psge'
				when 'Path'			then 'Path'
				when 'Paths'		then 'Path'
				when 'Pike'			then 'Pike'
				when 'Pikes'		then 'Pikes'
				when 'Pine'			then 'Pine'
				when 'Pines'		then 'Pnes'
				when 'Pnes'			then 'Pnes'
				when 'Place'		then 'Pl'
				when 'Pl'			then 'Pl'
				when 'Plain'		then 'Pln'
				when 'Pln'			then 'Pln'
				when 'Plains'		then 'Plns'
				when 'Plns'			then 'Plns'
				when 'Plaza'		then 'Plz'
				when 'Plz'			then 'Plz'
				when 'Plza'			then 'Plz'
				when 'Point'		then 'Pt'
				when 'Pt'			then 'Pt'
				when 'Points'		then 'Pts'
				when 'Pts'			then 'Pts'
				when 'Port'			then 'Prt'
				when 'Prt'			then 'Prt'
				when 'Ports'		then 'Prts'
				when 'Prts'			then 'Prts'
				when 'Pr'			then 'Pr'
				when 'Prairie'		then 'Pr'
				when 'Prr'			then 'Pr'
				when 'Rad'			then 'Radl'
				when 'Radial'		then 'Radl'
				when 'Radiel'		then 'Radl'
				when 'Radl'			then 'Radl'
				when 'Ramp'			then 'Ramp'
				when 'Ranch'		then 'Rnch'
				when 'Ranches'		then 'Rnch'
				when 'Rnch'			then 'Rnch'
				when 'Rnchs'		then 'Rnch'
				when 'Rapid'		then 'Rpd'
				when 'Rpd'			then 'Rpd'
				when 'Rapids'		then 'Rpds'
				when 'Rpds'			then 'Rpds'
				when 'Rest'			then 'Rst'
				when 'Rst'			then 'Rst'
				when 'Rdg'			then 'Rdg'
				when 'Rdge'			then 'Rdg'
				when 'Ridge'		then 'Rdg'
				when 'Ridges'		then 'Rdgs'
				when 'Rdgs'			then 'Rdgs'
				when 'Riv'			then 'Riv'
				when 'River'		then 'Riv'
				when 'Rvr'			then 'Riv'
				when 'Rivr'			then 'Riv'
				when 'Rd'			then 'Rd'
				when 'Rd.'			then 'Rd'
				when 'Road'			then 'Rd'
				when 'Roads'		then 'Rds'
				when 'Rds'			then 'Rds'
				when 'Route'		then 'Rte'
				when 'Row'			then 'Row'
				when 'Rue'			then 'Rue'
				when 'Shl'			then 'Shl'
				when 'Shoal'		then 'Shl'
				when 'Shls'			then 'Shls'
				when 'Shoals'		then 'Shls'
				when 'Shoar'		then 'Shr'
				when 'Shore'		then 'Shr'
				when 'Shr'			then 'Shr'
				when 'Shoars'		then 'Shrs'
				when 'Shores'		then 'Shrs'
				when 'Shrs'			then 'Shrs'
				when 'Skyway'		then 'Skwy'
				when 'Spg'			then 'Spg'
				when 'Spng'			then 'Spg'
				when 'Spring'		then 'Spg'
				when 'Sprng'		then 'Spg'
				when 'Spgs'			then 'Spgs'
				when 'Spngs'		then 'Spgs'
				when 'Springs'		then 'Spgs'
				when 'Sprngs'		then 'Spgs'
				when 'Spur'			then 'Spur'
				when 'Spurs'		then 'Spurs'
				when 'Sq'			then 'Sq'
				when 'Sqr'			then 'Sq'
				when 'Sqre'			then 'Sq'
				when 'Squ'			then 'Sq'
				when 'Square'		then 'Sq'
				when 'Sqrs'			then 'Sqs'
				when 'Squares'		then 'Sqs'
				when 'Sta'			then 'Sta'
				when 'Station'		then 'Sta'
				when 'Statn'		then 'Sta'
				when 'Stn'			then 'Sta'
				when 'Stra'			then 'Stra'
				when 'Strav'		then 'Stra'
				when 'Straven'		then 'Stra'
				when 'Stravenue'	then 'Stra'
				when 'Stravn'		then 'Stra'
				when 'Strvn'		then 'Stra'
				when 'Strvnue'		then 'Stra'
				when 'Stream'		then 'Strm'
				when 'Streme'		then 'Strm'
				when 'Strm'			then 'Strm'
				when 'Street'		then 'St'
				when 'St.'			then 'St'
				when 'St'			then 'St'
				when 'Str'			then 'St'
				when 'Steet'		then 'St'
				when 'Strt'			then 'St'
				when 'Streets'		then 'Sts'
				when 'Smt'			then 'Smt'
				when 'Sumit'		then 'Smt'
				when 'Sumitt'		then 'Smt'
				when 'Summit'		then 'Smt'
				when 'Ter'			then 'Ter'
				when 'Terr'			then 'Terr'
				when 'Terrace'		then 'Ter'
				when 'Througway'	then 'Trwy'
				when 'Trace'		then 'Trce'
				when 'Traces'		then 'Trce'
				when 'Trce'			then 'Trce'
				when 'Track'		then 'Trak'
				when 'Tracks'		then 'Trak'
				when 'Trak'			then 'Trak'
				when 'Trk'			then 'Trak'
				when 'Trks'			then 'Trak'
				when 'Trafficway'	then 'Trfy'
				when 'Trail'		then 'Trl'
				when 'Trails'		then 'Trl'
				when 'Trl'			then 'Trl'
				when 'Trls'			then 'Trls'
				when 'Trailer'		then 'Trlr'
				when 'Trlr'			then 'Trlr'
				when 'Trlrs'		then 'Trlr'
				when 'Tunel'		then 'Tunl'
				when 'Tunl'			then 'Tunl'
				when 'Tunls'		then 'Tunl'
				when 'Tunnel'		then 'Tunl'
				when 'Tunnels'		then 'Tunl'
				when 'Tunnl'		then 'Tunl'
				when 'Turnpike'		then 'Tpke'
				when 'Trnpk'		then 'Tpke'
				when 'Turnpk'		then 'Tpke'
				when 'Underpass'	then 'Upas'
				when 'Un'			then 'Un'
				when 'Union'		then 'Un'
				when 'Unions'		then 'Uns'
				when 'Valley'		then 'Vly'
				when 'Vally'		then 'Vly'
				when 'Vlly'			then 'Vly'
				when 'Vly'			then 'Vly'
				when 'Valleys'		then 'Vlys'
				when 'Vlys'			then 'Vlys'
				when 'Vdct'			then 'Via'
				when 'Via'			then 'Via'
				when 'Viadct'		then 'Via'
				when 'Viaduct'		then 'Via'
				when 'View'			then 'Vw'
				when 'Vw'			then 'Vw'
				when 'Views'		then 'Vws'
				when 'Vws'			then 'Vws'
				when 'Vill'			then 'Vlg'
				when 'Villag'		then 'Vlg'
				when 'Village'		then 'Vlg'
				when 'Villg'		then 'Vlg'
				when 'Villiage'		then 'Vlg'
				when 'Vlg'			then 'Vlg'
				when 'Villages'		then 'Vlgs'
				when 'Vlgs'			then 'Vlgs'
				when 'Ville'		then 'Vl'
				when 'Vl'			then 'Vl'
				when 'Vista'		then 'Vis'
				when 'Vist'			then 'Vis'
				when 'Vista'		then 'Vista'
				when 'Vst'			then 'Vis'
				when 'Vsta'			then 'Vis'
				when 'Walk'			then 'Walk'
				when 'Walks'		then 'Walk'
				when 'Wall'			then 'Wall'
				when 'Wy'			then 'Way'
				when 'Way'			then 'Way'
				when 'Ways'			then 'Ways'
				when 'Well'			then 'Wl'
				when 'Wells'		then 'Wls'
				when 'Wls'			then 'Wls'
			else @str1 end
		if (charindex(';'+@str1+';', ';aly;anx;arc;ave;byu;bch;bnd;blf;blfs;btm;blvd;br;brg;brk;brks;bg;bgs;byp;
			cp;cyn;cpe;cswy;ctr;ctrs;cir;cirs;clf;clfs;clb;cmn;cmns;cor;cors;crse;ct;cts;cv;cvs;crk;cres;crst;xing;xrd;xrds;curv;
			dl;dm;dv;dr;drs;est;ests;expy;ext;exts;fall;fls;fry;fld;flds;flt;frd;frds;frst;frg;frgs;frk;frks;ft;fwy;gdn;gdns;gtwy;
			gln;glns;grn;grns;grv;grvs;hbr;hbrs;hvn;hts;hwy;hl;hls;holw;inlt;is;iss;isle;jct;jcts;ky;kys;knl;knls;lk;lks;land;lndg;
			ln;lgt;lts;lf;lck;lcks;ldg;loop;mall;mnr;mnrs;mdw;mdws;mews;ml;mls;msn;mtwy;mt;mtn;mtns;nck;orch;oval;opas;park;pkwy;
			pass;psge;path;pike;pne;pnes;pl;pln;plns;plz;pt;pts;prt;prts;pr;radl;ramp;rnch;rpd;rpds;rst;rdg;rdgs;riv;rd;rds;rte;
			row;rue;run;shl;shls;shr;shrs;skwy;spgs;spur;sq;sqs;sta;stra;strm;st;sts;smt;ter;trwy;trce;trak;trfy;trl;trlr;tunl;tpke;
			upas;un;uns;vly;vlys;via;vw;vws;vlg;vlgs;vl;vis;walk;way;ways;wl;wls;'
		) > 0)
		select  @tp = @str1,
				@str = rtrim(substring(@str, 1, @i))
	end
	
	set @str1 = right(@city, 5)
	if (len(@city) >= 5 and isnumeric(@str1)=1 and @str > '00000')
		select @zip = @str1,
				@city = rtrim(substring(@city, 1, len(@city)-5))

	set @i = len(@city) - charindex(' ', reverse(@city))
	if (@i > 0 and @i < len(@city) and len(ltrim(substring(@city, @i+1, 999)))=2)
		select  @state= ltrim(substring(@city, @i+1, 9999)),
				@city = rtrim(substring(@city, 1, @i))
