# NewsObject class
require 'JSON'
require 'Date'

class HNDepart
	TODAY = 0
	SA = 1
	SME = 2
end

class HNType
	NEWS = 0
	ANNOUNCEMENT = 1
end

class NewsObject

	def initialize(department, type, object)
		@department = department
		@type = type
		@object = object
	end

	def type
		case @type
		when HNType::NEWS
			"news"
		when HNType::ANNOUNCEMENT
			"announcement"
		else
			"other"
		end
	end

	def department
		case @department
		when HNDepart::TODAY
			"today.hit.edu.cn"
		when HNDepart::SA
			"sa.hit.edu.cn"
		when HNDepart::SME
			"sme.hit.edu.cn"
		else
			"other"
		end
	end

	def date
		if @object.has_key?"date"
			dateString = @object["date"]
			date = dateString.split(' ')[0]
			time = dateString.split(' ')[1]
			DateTime.new(date.split('-')[0].to_i,
			 date.split('-')[1].to_i,
			  date.split('-')[2].to_i,
			   time.split(':')[0].to_i,
			    time.split(':')[1].to_i,
			     time.split(':')[2].to_i, '+8')
		end
	end

	def save
		date = self.date
		# Save to local
		if !Dir.exist?self.department
			Dir.mkdir(self.department)
		end
		if @object.has_key?:title
			filePath = self.department + '/' +date.year.to_s + '-' + format('%02d', date.month) + '-' + format('%02d', date.day) + '-' + self.type + '-' + @object[:title] + '.json'
			string = self.toJSON
			File.open(filePath, 'w:UTF-8') { |file|
				file.write(string)
			}
		end
		# Save to DB
		# To-do
	end

	def toJSON
		JSON.pretty_generate(@object)
	end

end