class Sale < ActiveRecord::Base
include AASM

	before_create :populate_guid
	belongs_to :book
	
	aasm column: 'state' do 
		state :pending, intial: true
		state :processing
		state :finished
		state :errored

		event :process, after: :charge_card do
			transitions from: :pending, to: :processing
		end

		event :finish do
			transitions from: :processing, to: :finished
		end

		event :fail do
			transitions from: :processing, to: :errored
		end
	end

	def charge_card
		begin
			save!
			charge = Stripe::Charge.create(
				amount: self.amount,
				currency: "usd",
				card: self.stripe_token,
				description: "Book Sale"
				)
			self.update(stripe_id: charge.id)
			self.finish!
		rescue Stripe::StripeError => each
			self.update_attributes(error: e.message)
			self.fail!
		end
	end
	def populate_guid
		self.guid = SecureRandom.uuid()
	end

end
