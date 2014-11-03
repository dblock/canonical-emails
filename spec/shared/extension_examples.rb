shared_examples 'extension fixture_examples' do
  yml_examples.each do |example|
    it "#{example['transforms'].join(', ')}" do
      klass = Class.new do
        include CanonicalEmails::Extensions
        attr_accessor :email
        canonical_email :email, * example['transforms'].map(&:constantize)
      end
      user = klass.new
      user.email = example['email']
      expect(user.canonical_email.to_s).to eq(example['canonical_email'])
    end
  end
end
